const CHAVE_PACIENTE = "vacina_app_paciente";
const CHAVE_DOSES = "vacina_app_doses";

// Preferences usa Keychain/UserDefaults no iOS nativo (não é apagado pela
// limpeza de dados de WebView, ao contrário de localStorage puro). No
// navegador, cai automaticamente para localStorage como fallback de teste.
const { Preferences } = window.CapacitorPreferences;
const { Filesystem, Directory, Encoding } = window.CapacitorFilesystem;
const { Share } = window.CapacitorShare;

// ---------- Navegação por abas ----------
document.querySelectorAll(".tab-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".tab-btn").forEach((b) => b.classList.remove("active"));
    document.querySelectorAll(".tab-panel").forEach((p) => p.classList.remove("active"));
    btn.classList.add("active");
    document.getElementById("tab-" + btn.dataset.tab).classList.add("active");
  });
});

// ---------- Acesso a dados (Preferences) ----------
async function lerJSON(chave, valorPadrao) {
  const { value } = await Preferences.get({ key: chave });
  if (!value) return valorPadrao;
  try {
    return JSON.parse(value);
  } catch {
    return valorPadrao;
  }
}

async function gravarJSON(chave, valor) {
  await Preferences.set({ key: chave, value: JSON.stringify(valor) });
}

async function carregarPacienteDados() {
  return lerJSON(CHAVE_PACIENTE, {
    unidadeSaude: "",
    nome: "",
    cpf: "",
    dataNascimento: "",
  });
}

async function carregarDosesDados() {
  return lerJSON(CHAVE_DOSES, []);
}

// ---------- Paciente ----------
async function preencherFormularioPaciente() {
  const paciente = await carregarPacienteDados();
  document.getElementById("unidadeSaude").value = paciente.unidadeSaude || "";
  document.getElementById("nome").value = paciente.nome || "";
  document.getElementById("cpf").value = paciente.cpf || "";
  document.getElementById("dataNascimento").value = paciente.dataNascimento || "";
}

async function salvarPaciente() {
  const nome = document.getElementById("nome").value.trim();
  if (!nome) {
    alert("Informe o nome do paciente.");
    return;
  }
  const paciente = {
    unidadeSaude: document.getElementById("unidadeSaude").value.trim(),
    nome,
    cpf: document.getElementById("cpf").value.trim(),
    dataNascimento: document.getElementById("dataNascimento").value,
  };
  await gravarJSON(CHAVE_PACIENTE, paciente);
  alert("Dados do paciente salvos.");
}

document.getElementById("btn-salvar-paciente").addEventListener("click", salvarPaciente);

// ---------- Doses ----------
function formatarData(iso) {
  if (!iso) return "-";
  const [ano, mes, dia] = iso.split("-");
  return `${dia}/${mes}/${ano}`;
}

async function renderizarDoses() {
  const doses = await carregarDosesDados();
  const lista = document.getElementById("lista-doses");
  const vazio = document.getElementById("doses-vazio");
  const contador = document.getElementById("doses-count");

  contador.textContent = `(${doses.length})`;
  lista.innerHTML = "";

  if (doses.length === 0) {
    vazio.classList.remove("hidden");
    return;
  }
  vazio.classList.add("hidden");

  doses.forEach((dose) => {
    const li = document.createElement("li");

    const info = document.createElement("div");
    const titulo = document.createElement("p");
    titulo.className = "dose-info-titulo";
    titulo.textContent = `${dose.vacina} - ${dose.numeroDose}ª dose`;

    const linha1 = document.createElement("p");
    linha1.className = "dose-info-linha";
    linha1.textContent = `${dose.fabricante || "-"} | Lote: ${dose.lote || "-"}`;

    const linha2 = document.createElement("p");
    linha2.className = "dose-info-linha";
    linha2.textContent = `Data: ${formatarData(dose.dataAplicacao)} | Vacinador: ${dose.vacinador || "-"}`;

    info.appendChild(titulo);
    info.appendChild(linha1);
    info.appendChild(linha2);

    const btnRemover = document.createElement("button");
    btnRemover.className = "btn-remover";
    btnRemover.textContent = "Remover";
    btnRemover.addEventListener("click", () => confirmarRemocaoDose(dose));

    li.appendChild(info);
    li.appendChild(btnRemover);
    lista.appendChild(li);
  });
}

async function adicionarDose() {
  const dataAplicacao = document.getElementById("dataAplicacao").value;
  if (!dataAplicacao) {
    alert("Informe a data de aplicação.");
    return;
  }
  const dose = {
    id: Date.now().toString(),
    vacina: document.getElementById("vacina").value,
    numeroDose: document.getElementById("numeroDose").value,
    fabricante: document.getElementById("fabricante").value.trim(),
    lote: document.getElementById("lote").value.trim(),
    dataAplicacao,
    vacinador: document.getElementById("vacinador").value.trim(),
  };

  const doses = await carregarDosesDados();
  doses.push(dose);
  await gravarJSON(CHAVE_DOSES, doses);
  await renderizarDoses();

  // limpar formulário
  document.getElementById("fabricante").value = "";
  document.getElementById("lote").value = "";
  document.getElementById("dataAplicacao").value = "";
  document.getElementById("vacinador").value = "";
}

// Confirmação antes de remover: uma dose apagada não tem como voltar
// (não existe lixeira/desfazer), por isso pede confirmação explícita
// mostrando qual dose será removida.
function confirmarRemocaoDose(dose) {
  const confirmou = window.confirm(
    `Remover "${dose.vacina} - ${dose.numeroDose}ª dose" (${formatarData(dose.dataAplicacao)})?\n\nEssa ação não pode ser desfeita.`
  );
  if (confirmou) {
    removerDose(dose.id);
  }
}

async function removerDose(id) {
  const doses = await carregarDosesDados();
  const atualizadas = doses.filter((d) => d.id !== id);
  await gravarJSON(CHAVE_DOSES, atualizadas);
  await renderizarDoses();
}

document.getElementById("btn-add-dose").addEventListener("click", adicionarDose);

// ---------- Exportar / Importar ----------
function mostrarStatus(mensagem, ehErro = false) {
  const el = document.getElementById("dados-status");
  el.textContent = mensagem;
  el.classList.remove("hidden", "erro");
  if (ehErro) el.classList.add("erro");
}

async function exportarDados() {
  try {
    const paciente = await carregarPacienteDados();
    const doses = await carregarDosesDados();
    const conteudo = JSON.stringify(
      { versao: 1, exportadoEm: new Date().toISOString(), paciente, doses },
      null,
      2
    );
    const nomeArquivo = `vacina-app-backup-${Date.now()}.json`;

    // Grava em um diretório temporário do app e abre a folha de
    // compartilhamento nativa do iOS (AirDrop, Arquivos, e-mail etc.)
    await Filesystem.writeFile({
      path: nomeArquivo,
      data: conteudo,
      directory: Directory.Cache,
      encoding: Encoding.UTF8,
    });
    const { uri } = await Filesystem.getUri({ path: nomeArquivo, directory: Directory.Cache });

    await Share.share({
      title: "Backup - Vacina App",
      url: uri,
      dialogTitle: "Salvar ou enviar backup",
    });

    mostrarStatus("Backup exportado. Guarde o arquivo em local seguro (Arquivos, e-mail, AirDrop...).");
  } catch (erro) {
    // Fallback para teste no navegador, onde Filesystem/Share nativos
    // não existem: baixa o JSON como arquivo comum.
    try {
      const paciente = await carregarPacienteDados();
      const doses = await carregarDosesDados();
      const conteudo = JSON.stringify({ versao: 1, paciente, doses }, null, 2);
      const blob = new Blob([conteudo], { type: "application/json" });
      const link = document.createElement("a");
      link.href = URL.createObjectURL(blob);
      link.download = `vacina-app-backup-${Date.now()}.json`;
      link.click();
      mostrarStatus("Backup baixado (modo navegador).");
    } catch (erroFallback) {
      mostrarStatus("Não foi possível exportar os dados. Tente novamente.", true);
    }
  }
}

async function importarDados(arquivo) {
  try {
    const texto = await arquivo.text();
    const dados = JSON.parse(texto);

    if (!dados || typeof dados !== "object" || !("paciente" in dados) || !("doses" in dados)) {
      mostrarStatus("Arquivo inválido: não parece ser um backup deste app.", true);
      return;
    }

    const confirmou = window.confirm(
      "Importar este backup vai substituir os dados atuais do app. Deseja continuar?"
    );
    if (!confirmou) return;

    await gravarJSON(CHAVE_PACIENTE, dados.paciente || {});
    await gravarJSON(CHAVE_DOSES, dados.doses || []);

    await preencherFormularioPaciente();
    await renderizarDoses();

    mostrarStatus("Dados importados com sucesso.");
  } catch (erro) {
    mostrarStatus("Não foi possível ler esse arquivo. Verifique se é um backup válido.", true);
  }
}

document.getElementById("btn-exportar").addEventListener("click", exportarDados);

document.getElementById("btn-importar").addEventListener("click", () => {
  document.getElementById("input-importar").click();
});

document.getElementById("input-importar").addEventListener("change", (evento) => {
  const arquivo = evento.target.files[0];
  if (arquivo) importarDados(arquivo);
  evento.target.value = ""; // permite selecionar o mesmo arquivo de novo depois
});

// ---------- Inicialização ----------
preencherFormularioPaciente();
renderizarDoses();
