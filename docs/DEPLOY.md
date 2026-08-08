# Deploy gratuito

O projeto tem três peças com necessidades diferentes:

| Peça | O que é | Precisa de |
|---|---|---|
| `web` | bundle Flutter (arquivos estáticos) | qualquer host estático — grátis em todo lugar |
| `api` | container Spring Boot | ~400–512 MB de RAM, sempre no ar |
| `db` | PostgreSQL | disco persistente |

O gargalo é a **API + banco**. O app web é a parte fácil.

## Números reais deste projeto

Medidos na instalação local, para você escolher o plano com base em fato:

| Item | Tamanho |
|---|---|
| Banco recém-instalado (catálogo com 834 exercícios) | ~11 MB |
| Cada mídia em cache (`media_cache`) | ~400 KB |
| Banco com **todas** as 360 imagens em cache | ~150 MB |
| Imagem Docker da API | ~250 MB |
| Bundle web (release) | ~4 MB |
| Heap da API em regime | ~250–400 MB |

O `media_cache` é o que cresce: ele guarda os bytes das imagens do wger dentro
do Postgres para o app funcionar sem internet. Em free tier de banco pequeno,
veja "Enxugando para caber" no fim.

---

## Opção 0 — Azure for Students (GitHub Student Pack)

O que a oferta garante: **US$ 100 de crédito por ano, sem cartão de crédito**,
renovável enquanto você for estudante ([detalhes da oferta](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0170p)).

Uma ressalva que evita surpresa: a lista de "20+ serviços grátis por 12 meses"
(que inclui PostgreSQL B1ms) é documentada para a **Azure free account**, que é
uma oferta diferente do Azure for Students. Não conte com o Postgres gerenciado
de graça: um B1ms custa ~US$ 12–15/mês e consumiria o crédito em ~7 meses.

Por isso o arranjo abaixo **não gasta o crédito** — ele fica de reserva:

| Peça | Onde | Custo |
|---|---|---|
| `api` | Azure Container Apps (plano de consumo) | dentro da cota gratuita |
| `db` | Neon | gratuito, sem prazo |
| `web` | Azure Static Web Apps (plano Free) | gratuito, sem prazo |

O Container Apps tem cota gratuita mensal **por assinatura** de 180.000 vCPU-s,
360.000 GiB-s e 2 milhões de requisições ([preços](https://azure.microsoft.com/en-us/pricing/details/container-apps/)),
e escala a zero. Para uso pessoal isso sobra.

### Passo 1 — banco no Neon

Crie um projeto em [neon.tech](https://neon.tech) e monte a URL JDBC:

```
jdbc:postgresql://ep-xxxx-yyyy.sa-east-1.aws.neon.tech/neondb?sslmode=require
```

O Flyway cria o schema e o catálogo de 834 exercícios no primeiro boot.

### Passo 2 — imagem da API no GHCR

O repositório já tem o workflow. Rode a action **"Imagem da API"** (ou faça um
push em `backend/`) e depois deixe o pacote público em
*Settings → Packages → meu-treino-api → Change visibility*, para o Azure baixar
sem credencial.

### Passo 3 — API no Container Apps

```bash
az login
export DB_URL='jdbc:postgresql://ep-xxxx.sa-east-1.aws.neon.tech/neondb?sslmode=require'
export DB_USER='seu_usuario'
export DB_PASSWORD='sua_senha'
export IMAGE='ghcr.io/felipemacedo1/meu-treino-api:latest'

bash infra/azure/deploy-api.sh
```

O script cria o resource group, o ambiente e a aplicação, gera um `JWT_SECRET`
aleatório, guarda senha e segredo como *secrets* do Container App, e imprime a
URL pública no fim.

### Passo 4 — app web no Static Web Apps

Crie um recurso Static Web App (plano **Free**), fonte "GitHub", e copie o
*deployment token*. No repositório, em *Settings → Secrets and variables →
Actions*:

- secret `AZURE_STATIC_WEB_APPS_API_TOKEN` = o token
- variable `API_BASE_URL` = `https://sua-api.<região>.azurecontainerapps.io/api`

Rode a action **"App web (Azure Static Web Apps)"**. O `staticwebapp.config.json`
já está no repositório devolvendo `index.html` em qualquer rota — sem isso, dar
F5 em `/workouts/3` daria 404.

### Passo 5 — fechar o CORS

Depois de saber o domínio do app:

```bash
az containerapp update -g meu-treino -n meu-treino-api \
  --set-env-vars CORS_ALLOWED_ORIGINS=https://SEU-APP.azurestaticapps.net
```

### Passo 6 — APK

Na tela de login, em **Servidor**, coloque a URL da API. Como é HTTPS, não há
problema de cleartext.

### O que esperar

- **Cold start.** Com `--min-replicas 0` a primeira requisição depois de um
  período parado espera o container subir (~7s de boot da API + o tempo de
  alocação). Aceitável para uso pessoal; se incomodar, troque para
  `--min-replicas 1` — sai da cota gratuita e passa a consumir o crédito
  (na ordem de ~US$ 25–30/mês com 0.5 vCPU, ou seja, ~3 meses de crédito).
- **Espaço no Neon.** O cache de mídias pode levar o banco a ~150 MB, contra
  ~0,5 GB do plano gratuito. Cabe, mas veja "Enxugando para caber" no fim.
- **Região.** `brazilsouth` reduz latência daqui; se o Container Apps não
  estiver disponível na sua assinatura lá, use `eastus`.

> Vale conferir também os outros créditos do Student Pack. Alguns parceiros dão
> crédito de VM (DigitalOcean, por exemplo) que, num droplet de ~US$ 6/mês,
> rodaria o `docker compose` inteiro sempre ligado por bem mais tempo do que os
> US$ 100 da Azure. As ofertas mudam — confira em
> [education.github.com/pack](https://education.github.com/pack).

---

## Opção 1 — Oracle Cloud Always Free

Uma VM ARM gratuita "para sempre", onde você roda **o `docker compose` inteiro**,
exatamente como na sua máquina. Sem adaptação, sem serviço dormindo.

- Always Free inclui VM `VM.Standard.A1.Flex` (Ampere ARM). O limite foi
  reduzido em junho de 2026 de 4 OCPU/24 GB para **2 OCPU/12 GB** — ainda é
  muito mais do que este projeto precisa. Também inclui 200 GB de block storage.
- Exige cartão para validação de identidade, mas os recursos Always Free não
  expiram ([documentação da Oracle](https://docs.oracle.com/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)).

Passos:

```bash
# na VM (Ubuntu 24.04 ARM)
sudo apt update && sudo apt install -y docker.io git
sudo usermod -aG docker $USER && newgrp docker
bash <(curl -fsSL https://raw.githubusercontent.com/docker/compose/v5.4.0/scripts/…)  # ou: scripts/install-compose-v2.sh

git clone https://github.com/felipemacedo1/meu_treino.git
cd meu_treino
cp .env.example .env
# edite o .env: JWT_SECRET aleatório e CORS_ALLOWED_ORIGINS com seu domínio
bash scripts/start.sh
```

Depois libere as portas 80/443 na *security list* da VNIC e no `iptables` da VM
(o Oracle Linux/Ubuntu da OCI vem com o firewall fechado por padrão).

As imagens do projeto compilam em ARM sem mudança: o `Dockerfile` da API usa
`maven:3.9-eclipse-temurin-21` e `eclipse-temurin:21-jre`, ambos multi-arch, e o
`web` usa `nginx:alpine`.

**Antes de expor na internet**, faça o que está na seção Segurança do README:
`JWT_SECRET` novo, `CORS_ALLOWED_ORIGINS` restrito, senha do Postgres trocada,
porta do banco não publicada e HTTPS na frente (Caddy ou Nginx + Let's Encrypt).

---

## Opção 2 — Render (mais simples, mas a API dorme)

Free tier sem cartão. O ponto de atenção: **web services gratuitos hibernam
após ~15 min sem tráfego** e levam alguns segundos para acordar. Para uso
pessoal na academia isso significa esperar o primeiro carregamento.

- `api`: Web Service a partir do `backend/Dockerfile` (512 MB).
- `db`: Postgres gerenciado do Render no plano free — atenção, ele **expira**
  depois de um período; confira o prazo atual no painel antes de confiar dados
  nele.
- `web`: Static Site com build `flutter build web --release` e publish
  `app/build/web`.

Variáveis na `api`: `DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`,
`CORS_ALLOWED_ORIGINS`.

---

## Opção 3 — Banco separado + container em qualquer lugar

Combinação flexível: um Postgres gerenciado grátis + a API onde for mais
conveniente.

Postgres grátis (limites de 2026, confirme antes):

| Serviço | Free tier | Pegadinha |
|---|---|---|
| **Neon** | ~0.5 GB | escala a zero após ~5 min, acorda em menos de 1s |
| **Supabase** | 500 MB | projeto **pausa após 7 dias** ocioso e precisa ser restaurado à mão |
| **Aiven** | plano free de Postgres | recursos modestos, bom para começar |

Para a API: Koyeb, Google Cloud Run, Fly.io ou Railway (crédito mensual de
US$ 5). Todos aceitam `Dockerfile`.

Com Neon ou Supabase, aponte a API com:

```
DB_URL=jdbc:postgresql://<host>/<db>?sslmode=require
DB_USER=...
DB_PASSWORD=...
```

O Flyway roda as migrations no primeiro boot, então o catálogo de 834
exercícios é criado automaticamente.

---

## O app web (grátis em qualquer host estático)

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://sua-api.exemplo.com/api
# publique app/build/web em Cloudflare Pages, Netlify, Vercel ou GitHub Pages
```

Dois cuidados:

1. `API_BASE_URL` precisa apontar para a API pública. O valor `/api` só funciona
   quando o nginx do projeto serve as duas coisas no mesmo host.
2. Se o app e a API ficarem em domínios diferentes, ajuste
   `CORS_ALLOWED_ORIGINS` na API para o domínio do app (não deixe `*`).
3. O host estático precisa devolver `index.html` para qualquer rota, senão
   recarregar `/workouts/3` dá 404 (o app usa URLs de caminho).

---

## Android e iOS

O APK não precisa de deploy: ele fala direto com a sua API. Na tela de login,
em **Servidor**, aponte para o endereço público (ou o IP da LAN). Veja
`scripts/build-apk.sh`.

No iOS não há APK. Use o PWA: abra o app no Safari e toque em
*Compartilhar → Adicionar à Tela de Início*. Gerar um `.ipa` exige macOS com
Xcode e conta de desenvolvedor Apple.

---

## Enxugando para caber em free tier pequeno

Se o banco gratuito for de 500 MB e você quiser folga:

1. **Não pré-aqueça o cache de mídias.** Ele preenche sob demanda; só as
   imagens que você realmente abriu ocupam espaço.
2. **Limpe o cache quando quiser espaço de volta** — as imagens são rebaixadas
   do wger na próxima vez que aparecerem:
   ```sql
   TRUNCATE media_cache;
   ```
3. **Ou deixe o app apontar direto para o wger**, sem cache local. Custa a
   dependência de internet para ver imagens, mas o banco fica em ~11 MB. Exige
   uma pequena mudança em `ExerciseMapper` (usar a URL original em vez de
   `mediaService.publicUrl`).
4. `WGER_SYNC_ON_STARTUP=false` evita qualquer chamada externa no boot (o
   catálogo já vem nas migrations).

---

## Resumo

- **Tem GitHub Student Pack:** Azure Container Apps + Neon + Static Web Apps.
  Fica dentro das cotas gratuitas e preserva o crédito de US$ 100. Scripts e
  workflows prontos no repositório.
- **Quer o projeto inteiro rodando de graça e sem dormir:** Oracle Cloud Always
  Free, com o `docker compose` como está.
- **Quer o caminho mais rápido e aceita a API hibernar:** Render.
- **Quer banco robusto e API leve:** Neon (banco) + Koyeb/Cloud Run (API) +
  Cloudflare Pages (app).
- **Só quer usar na sua rede:** não faça deploy. `make up` na sua máquina e o
  APK apontando para o IP da LAN já resolve.

> Free tiers mudam com frequência. Os limites acima são de meados de 2026 —
> confirme no painel do provedor antes de decidir.
