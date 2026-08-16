const CHAVE_PACIENTE = "vacina_app_paciente";
const CHAVE_DOSES = "vacina_app_doses";

// ---------- Navegação por abas ----------
document.querySelectorAll(".tab-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".tab-btn").forEach((b) => b.classList.remove("active"));
    document.querySelectorAll(".tab-panel").forEach((p) => p.classList.remove("active"));
    btn.classList.add("active");
    document.getElementById("tab-" + btn.dataset.tab).classList.add("active");
  });
});

// ---------- Paciente ----------
function carregarPaciente() {
  const raw = localStorage.getItem(CHAVE_PACIENTE);
  const paciente = raw ? JSON.parse(raw) : {};
  document.getElementById("unidadeSaude").value = paciente.unidadeSaude || "";
  document.getElementById("nome").value = paciente.nome || "";
  document.getElementById("cpf").value = paciente.cpf || "";
  document.getElementById("dataNascimento").value = paciente.dataNascimento || "";
}

function salvarPaciente() {
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
  localStorage.setItem(CHAVE_PACIENTE, JSON.stringify(paciente));
  alert("Dados do paciente salvos.");
}

document.getElementById("btn-salvar-paciente").addEventListener("click", salvarPaciente);

// ---------- Doses ----------
function carregarDoses() {
  const raw = localStorage.getItem(CHAVE_DOSES);
  return raw ? JSON.parse(raw) : [];
}

function salvarDoses(doses) {
  localStorage.setItem(CHAVE_DOSES, JSON.stringify(doses));
}

function formatarData(iso) {
  if (!iso) return "-";
  const [ano, mes, dia] = iso.split("-");
  return `${dia}/${mes}/${ano}`;
}

function renderizarDoses() {
  const doses = carregarDoses();
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
    btnRemover.addEventListener("click", () => removerDose(dose.id));

    li.appendChild(info);
    li.appendChild(btnRemover);
    lista.appendChild(li);
  });
}

function adicionarDose() {
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

  const doses = carregarDoses();
  doses.push(dose);
  salvarDoses(doses);
  renderizarDoses();

  // limpar formulário
  document.getElementById("fabricante").value = "";
  document.getElementById("lote").value = "";
  document.getElementById("dataAplicacao").value = "";
  document.getElementById("vacinador").value = "";
}

function removerDose(id) {
  const doses = carregarDoses().filter((d) => d.id !== id);
  salvarDoses(doses);
  renderizarDoses();
}

document.getElementById("btn-add-dose").addEventListener("click", adicionarDose);

// ---------- Inicialização ----------
carregarPaciente();
renderizarDoses();
