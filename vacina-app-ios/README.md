# Vacina App (iOS — HTML/CSS/JS + Capacitor)

App para cadastrar os dados do "Comprovante de Vacinação do Adulto", escrito
em JavaScript, HTML e CSS puros (sem React/frameworks de UI) e empacotado
como app iOS nativo com **Capacitor**.

Dados salvos localmente no aparelho (`localStorage`) — sem backend, sem
envio de dados pela rede.

## Testar rápido no navegador (antes de ir pro iOS)

Não precisa de nada instalado além de um navegador. Dentro da pasta `www/`,
abra `index.html` diretamente ou rode um servidor local:

```
cd www
python3 -m http.server 8080
```

Acesse `http://localhost:8080` — a interface e o armazenamento já funcionam
igual ao app nativo.

## Gerar o app iOS de verdade

Diferente do Expo (RN), o Capacitor **exige um Mac com Xcode instalado**
para compilar o app iOS — não existe build 100% na nuvem gratuita para
Capacitor como existe no Expo. Passos, já dentro da pasta do projeto:

```
npm install
npx cap add ios
npx cap sync
npx cap open ios
```

O último comando abre o projeto no Xcode. De lá:

- **Testar no Simulador**: escolha um iPhone simulado e aperte "Play" — não
  precisa de conta Apple paga.
- **Testar em iPhone físico**: precisa de uma Apple ID gratuita (assinatura
  de desenvolvimento por 7 dias) ou conta Apple Developer paga (US$ 99/ano)
  para assinatura de 1 ano / distribuição via TestFlight ou App Store.

Sem Mac disponível, alternativas: pedir a build para um serviço de CI com
runner macOS (ex: GitHub Actions com `macos-latest`, ou Ionic Appflow —
pago), ou usar um Mac na nuvem (ex: MacStadium).

## Estrutura do projeto

```
vacina-app-ios/
├── www/
│   ├── index.html        # estrutura (abas Paciente / Doses)
│   ├── style.css          # visual estilo iOS (cores, tipografia, cards)
│   └── app.js              # lógica: localStorage, formulários, listas
├── capacitor.config.json
└── package.json
```

## Campos cobertos

- **Paciente**: unidade de saúde, nome, CPF, data de nascimento.
- **Dose**: vacina, número da dose (1/2/3/Reforço 1/Reforço 2), fabricante,
  lote, data de aplicação, vacinador.

## Diferença para a versão Android (Expo/React Native)

| | Esta versão (iOS) | Versão anterior (Android) |
|---|---|---|
| Linguagem de UI | HTML + CSS puro | JSX + `StyleSheet` (React Native) |
| Framework | Capacitor | Expo |
| Armazenamento | `localStorage` (Web Storage) | `AsyncStorage` |
| Build sem Mac/PC dedicado | Não (precisa Xcode) | Sim (`eas build` na nuvem) |

Se quiser, esse mesmo projeto `www/` também roda como PWA (útil para testar
rápido em qualquer iPhone via "Adicionar à Tela de Início" no Safari, sem
precisar de build nenhuma) — é só hospedar os arquivos de `www/` em qualquer
servidor estático.

## Limitações desta versão

- Single-paciente por instalação (sem múltiplos perfis).
- Sem validação de CPF.
- Sem sincronização/backup entre aparelhos.
