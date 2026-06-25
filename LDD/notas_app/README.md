# Notas Pessoais — Flutter + Firebase

Mini-app de **notas pessoais** construído com **Flutter** e **Firebase** (Authentication,
Cloud Firestore e Cloud Storage). Cada usuário se autentica, gerencia apenas as próprias
notas e visualiza um pequeno painel de perfil com estatísticas.

Trabalho da disciplina **Laboratório de Desenvolvimento para Aplicações Móveis (LDD)**.

---

## 1. Enunciado do exercício

> Desenvolver um mini-aplicativo de **Notas Pessoais** em Flutter integrado ao Firebase,
> contemplando autenticação de usuários, persistência de dados em nuvem, regras de
> segurança e um painel de perfil com estatísticas.

Requisitos:

1. **Autenticação completa**
   - Cadastro e login com e-mail/senha.
   - Logout e redefinição de senha por e-mail.
   - Ao cadastrar, criar um documento de perfil do usuário em `/users/{uid}`.
   - Navegação reativa: usuário logado vê a tela de notas; deslogado vê a tela de login.

2. **CRUD de notas no Cloud Firestore**
   - Cada nota possui `titulo`, `conteudo`, `createdAt` e `favorito`.
   - As notas ficam isoladas por usuário em `/notes/{uid}/items/{noteId}`.
   - Criar, listar (em tempo real) e excluir notas.

3. **Security Rules**
   - Garantir que cada usuário só consiga ler/gravar as próprias notas e o próprio perfil.

4. **Perfil e estatísticas**
   - Exibir nome, foto e contadores (total de notas e favoritas).

### Itens bônus implementados
- **Login com Google** (Google Sign-In) com importação da foto de perfil.
- **Upload de foto de perfil** para o Cloud Storage.
- **Filtro de favoritas** usando consulta com `.where('favorito', isEqualTo: true)`.
- **Gráfico de barras** (`fl_chart`) com a quantidade de notas por dia da semana.
- **Regra de exclusão temporal**: impede excluir notas criadas há mais de 7 dias.
- **Contador agregado** `notesCount` mantido com `FieldValue.increment`.

---

## 2. Como o exercício foi resolvido (passo a passo)

| Requisito | Onde está | Como foi feito |
|-----------|-----------|----------------|
| Bootstrap do Firebase | `lib/main.dart` | `Firebase.initializeApp` com `DefaultFirebaseOptions.currentPlatform`. |
| Navegação por estado de login | `lib/main.dart` | `StreamBuilder` ouvindo `FirebaseAuth.instance.authStateChanges()`. |
| Cadastro / login / reset / Google | `lib/auth_screen.dart` | `createUserWithEmailAndPassword`, `signInWithEmailAndPassword`, `sendPasswordResetEmail`, `signInWithCredential`. |
| Criação do perfil | `lib/auth_screen.dart` | `set` em `/users/{uid}` com `name`, `photo`, `role: 'user'`, `notesCount: 0`. |
| CRUD das notas | `lib/note_service.dart` | Coleção `/notes/{uid}/items`, com `batch` para criar/excluir e atualizar `notesCount`. |
| Listagem em tempo real | `lib/home_screen.dart` | `StreamBuilder` sobre `notesStream()`. |
| Excluir nota | `lib/home_screen.dart` | `Dismissible` (arrastar para a esquerda) → `deleteNote`. |
| Filtro de favoritas | `lib/note_service.dart` / `home_screen.dart` | `favoritesStream()` com `.where('favorito')`; alternância pelo ícone de estrela. |
| Foto de perfil | `lib/storage_service.dart` | `image_picker` → upload no Storage → salva URL em `/users/{uid}.photo`. |
| Estatísticas + gráfico | `lib/home_screen.dart` | `_ProfileHeader` e `_WeeklyChart` (`fl_chart`). |
| Regras Firestore | `firestore.rules` | Acesso por `request.auth.uid == uid` + bloqueio de exclusão após 7 dias. |
| Regras Storage | `storage.rules` | Leitura/escrita de `profile_pictures/` apenas para usuários autenticados. |

---

## 3. Explicação da aplicação

### Tecnologias e dependências (`pubspec.yaml`)

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` — integração com o Firebase.
- `google_sign_in` — login com conta Google.
- `image_picker` — seleção da foto de perfil na galeria.
- `fl_chart` — gráfico de barras das estatísticas.

### Estrutura de arquivos

```
lib/
  main.dart            # Inicializa o Firebase e decide a tela (login x notas)
  auth_screen.dart     # Login / cadastro / reset de senha / Google Sign-In
  home_screen.dart     # Perfil, estatísticas, gráfico e lista de notas (CRUD)
  note_service.dart    # Serviço de CRUD das notas + contador notesCount
  storage_service.dart # Upload da foto de perfil para o Cloud Storage
  firebase_options.dart# Configuração gerada pelo FlutterFire (por plataforma)
firestore.rules        # Regras de segurança do Firestore (/users e /notes)
storage.rules          # Regras de segurança do Storage (fotos de perfil)
firebase.json          # Aponta quais arquivos de regras/índices usar no deploy
firestore.indexes.json # Índices compostos do Firestore
web/index.html         # HTML da versão web (contém o client_id do Google)
android/app/google-services.json # Config Android do Firebase
```

### Modelo de dados no Firestore

```
/users/{uid}
  name        : String        # nome de exibição
  photo       : String        # URL da foto de perfil (ou "")
  role        : String        # "user" (usado nas regras)
  notesCount  : number        # total de notas (incrementado/decrementado)
  createdAt   : Timestamp

/notes/{uid}/items/{noteId}
  titulo      : String
  conteudo    : String
  createdAt   : Timestamp      # serverTimestamp
  favorito    : bool
```

Foto de perfil no Storage: `profile_pictures/{uid}.jpg`.

### Fluxo da aplicação

1. `main.dart` inicializa o Firebase e escuta `authStateChanges()`:
   - **sem usuário** → `AuthScreen`;
   - **com usuário** → `HomeScreen`.
2. No `AuthScreen`, ao cadastrar cria-se o documento `/users/{uid}`. No login com Google,
   o documento é criado na primeira vez.
3. No `HomeScreen`, o `StreamBuilder` consome `notesStream()` e renderiza o cabeçalho de
   perfil, o gráfico semanal e a lista de notas em tempo real.
4. Criar/excluir notas usa um `batch` que também ajusta `notesCount` no perfil.

### Regras de segurança

`firestore.rules`:
- `/users/{uid}`: o usuário lê/cria/atualiza o próprio perfil; não pode alterar o campo
  `role` nem excluir o documento.
- `/notes/{uid}/items/{noteId}`: leitura e escrita apenas quando `request.auth.uid == uid`;
  exclusão bloqueada para notas com mais de 7 dias.
- Qualquer outro caminho é negado por padrão.

`storage.rules`:
- `profile_pictures/`: leitura e escrita apenas para usuários autenticados; demais caminhos negados.

> **Importante:** as regras só valem depois de publicadas no Firebase. Veja a seção
> [Publicando as Security Rules](#5-publicando-as-security-rules).

---

## 4. Como rodar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.10.4`).
- [Firebase CLI](https://firebase.google.com/docs/cli) (para publicar regras).
- Um projeto Firebase com **Authentication** (e-mail/senha e Google), **Firestore** e **Storage** habilitados.

### Instalar dependências

```bash
flutter pub get
```

### Rodar no Android (emulador ou dispositivo)

```bash
flutter run
```

### Rodar na Web (Chrome)

Use uma **porta fixa** para que o login com Google funcione (ver observação abaixo):

```bash
flutter run -d chrome --web-port=5000
```

> **Login com Google na Web exige duas configurações:**
> 1. O **Web Client ID** precisa estar no `web/index.html`:
>    ```html
>    <meta name="google-signin-client_id" content="SEU_CLIENT_ID.apps.googleusercontent.com">
>    ```
> 2. A origem (ex.: `http://localhost:5000`) precisa estar em **Authorized JavaScript origins**
>    do cliente OAuth web, no [Google Cloud Console → Credenciais](https://console.cloud.google.com/apis/credentials).
>
> Sem isso, o login com Google falha com `ClientID not set` ou erro de origem não autorizada.
> O login por **e-mail/senha** funciona normalmente sem essas configurações.

---

## 5. Publicando as Security Rules

As regras em `firestore.rules` e `storage.rules` **não funcionam até serem publicadas**.
Se aparecer `[cloud_firestore/permission-denied] Missing or insufficient permissions`,
é porque elas ainda não foram enviadas ao Firebase.

```bash
# Login no Firebase CLI (abre o navegador)
firebase login

# Publica apenas as regras do Firestore
firebase deploy --only firestore:rules --project SEU_PROJECT_ID

# (Opcional) Publica as regras do Storage
firebase deploy --only storage --project SEU_PROJECT_ID
```

Alternativa sem CLI: copie o conteúdo dos arquivos `.rules` no Firebase Console
(**Firestore → Regras** e **Storage → Regras**) e clique em **Publicar**.

---

## 6. Como apontar para outro projeto Firebase

Para rodar este app em um **projeto Firebase diferente**, troque as credenciais. A forma
recomendada é regenerar tudo automaticamente; em seguida há a lista do que é alterado.

### Opção A — Automática (recomendada)

```bash
# Instala a CLI do FlutterFire (uma vez)
dart pub global activate flutterfire_cli

# Reconfigura o projeto: selecione o novo projeto e as plataformas desejadas
flutterfire configure
```

Isso regenera `lib/firebase_options.dart`, `android/app/google-services.json` e atualiza o
`firebase.json` com o novo `projectId`/`appId`.

### Opção B — Manual

Edite/substitua os seguintes arquivos com os dados do novo projeto:

1. **`lib/firebase_options.dart`** — `apiKey`, `appId`, `messagingSenderId`/`projectId`,
   `storageBucket` etc. de cada plataforma (web, android, ios...).
2. **`android/app/google-services.json`** — baixe o novo arquivo nas configurações do app
   Android no Firebase Console e substitua.
3. **`firebase.json`** — atualize `projectId` e `appId` nas seções `flutter.platforms`.
4. **`web/index.html`** — troque o `content` da meta tag `google-signin-client_id` pelo
   **Web Client ID** do novo projeto:
   ```html
   <meta name="google-signin-client_id" content="NOVO_CLIENT_ID.apps.googleusercontent.com">
   ```
   > O Web Client ID está no Google Cloud Console (Credenciais → "Web client (auto created
   > by Google Service)") ou dentro do `google-services.json` no campo `oauth_client` com
   > `client_type: 3`.
5. **`ios/Runner/GoogleService-Info.plist`** — substitua se for rodar no iOS.

### Depois de trocar o projeto

```bash
flutter pub get
firebase deploy --only firestore:rules --project NOVO_PROJECT_ID
flutter run -d chrome --web-port=5000   # ou: flutter run (Android)
```

E no **novo** projeto, no Firebase Console, habilite:
- **Authentication** → provedores **E-mail/senha** e **Google**;
- **Cloud Firestore** (criado o banco);
- **Cloud Storage**;
- adicione `http://localhost:5000` (e o domínio de produção) nas **Authorized JavaScript
  origins** do cliente OAuth web, para o login com Google na web.
