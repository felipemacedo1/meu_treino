# Notas de arquitetura

Documento curto com o "por quê" das decisões. O README cobre o "como usar".

## Backend

**Organização por feature, não por camada.** Cada pasta em `com.meutreino`
contém entidade, repositório, serviço, controller e DTOs da própria área. Isso
mantém o código de uma funcionalidade junto e evita o vaivém entre seis pastas
para uma mudança pequena. Clean Architecture completa (ports/adapters, casos de
uso isolados) foi deixada de fora de propósito: o ganho não pagaria o custo num
app pessoal com um único cliente.

**JWT stateless.** Sem sessão no servidor, sem refresh token. O token vale 60
dias e é guardado no `shared_preferences` do app. Um `OncePerRequestFilter`
coloca um `AuthPrincipal(userId, email)` no contexto do Spring Security, e os
controllers recebem via `@AuthenticationPrincipal`. Todo acesso a dados filtra
por `userId`, então um usuário nunca alcança dados de outro.

**Catálogo dentro do banco.** O maior risco de depender do wger em tempo de uso
é a academia sem sinal. A migration `V3__seed_exercises.sql` (401 KB, gerada por
`scripts/generate_exercise_seed.py`) insere os 834 exercícios com músculos,
equipamentos, imagens e vídeos. Consequência: o primeiro boot já tem catálogo
completo e o app funciona offline. `POST /api/sync/wger` continua existindo para
atualizar/complementar depois, rodando em background (`@Async`) com registro em
`sync_log`.

**Mídias via proxy com cache.** As imagens do wger são URLs remotas. Se o app
apontasse direto para lá, a academia sem sinal ficaria sem ilustração e cada
carregamento sairia da nossa infra. Então o backend expõe
`GET /api/media/{hash}`: na primeira requisição baixa o arquivo, guarda os bytes
em `media_cache` e responde com `Cache-Control` de um ano. O `hash` é resolvido
por um mapa em memória construído a partir de `exercise_images`/`exercise_videos`,
então só é possível buscar mídias que já existem no catálogo — nada de SSRF.

**Ordenação do catálogo.** 834 exercícios importados de uma base colaborativa
incluem muita coisa de qualidade irregular. A coluna `exercises.quality`
(migration `V6`) vale `2` se o exercício tem nome em português e `+1` se tem
imagem; a busca ordena por `quality DESC, name ASC`. É um campo materializado
justamente para a ordenação continuar sendo um índice simples.

**Filtros com Specifications.** A busca combina termo livre, músculo,
equipamento, categoria e "só com imagem". Foi feita com
`JpaSpecificationExecutor` em vez de JPQL com `:param IS NULL OR ...` porque
Specifications montam só os predicados presentes — sem parâmetros nulos com tipo
ambíguo e sem query gigante difícil de ler.

**Troca de exercício sem sujar a ficha.** `session_exercises` guarda
`exercise_id` (o que foi feito) e `original_exercise_id` (o que estava na ficha).
A ficha em `workout_exercises` não é tocada. O histórico mostra exatamente o que
aconteceu, e a próxima sessão volta ao exercício planejado.

**Séries pré-criadas ao iniciar a sessão.** `POST /api/sessions/start` já cria as
`session_sets` conforme `target_sets` do treino, cada uma com `target_reps` e a
carga alvo. Assim a tela de treino é só edição, sem "adicionar série" a cada
repetição — e séries extras continuam possíveis.

**Volume recalculado a cada mudança.** `session.total_volume` e `total_sets` são
recomputados no serviço a cada alteração de série (soma de `peso × reps` das
séries concluídas). Ficam materializados na sessão porque praticamente toda
estatística parte deles.

## App

**Riverpod 3 com `Notifier`/`AsyncNotifier`.** Sem code generation. Providers de
leitura são `FutureProvider` (invalidados quando algo muda); o que tem operações
são `AsyncNotifier`. A sessão ativa é um `AsyncNotifier<TrainingSession?>` — cada
endpoint de sessão devolve a sessão inteira, então o estado da tela é sempre o
que o servidor confirmou, sem merge manual.

**Ações da sessão em fila.** Marcar séries rápido gerava requisições
concorrentes e toques perdidos. `_guard` encadeia as ações em um `Future` serial:
nenhum toque é descartado e a última resposta é a que vale. O indicador de
sincronização fica no app bar, e nunca desabilita os botões de série.

**Cronômetros fora do `setState`.** O tempo decorrido e o descanso vivem em
`ValueNotifier`s consumidos por `ValueListenableBuilder`. Sem isso, o tique de um
segundo rebuildava a lista de exercícios e apagava valores digitados mas ainda
não salvos.

**Campos de carga/reps sincronizam só quando o servidor muda.**
`_SetRow.didUpdateWidget` compara o valor novo com o anterior do servidor e só
sobrescreve o `TextEditingController` se realmente mudou lá. Preserva o que o
usuário está digitando durante rebuilds.

**Web com URLs de caminho.** `usePathUrlStrategy()` + `try_files` no nginx dão
links limpos (`/workouts/3`) que funcionam ao recarregar a página.

**Alvo web/PWA primeiro.** O app instala na tela inicial do celular e funciona em
tela cheia, sem depender de loja nem de assinatura. A pasta `app/android` está
configurada para quem quiser gerar o APK.

## Infra

**Três serviços no compose**: `db` (Postgres 16), `api` (jar em Temurin 21) e
`web` (bundle Flutter servido por nginx). O nginx também faz proxy de `/api`
para a API, o que elimina CORS em produção e permite usar `API_BASE_URL=/api`.

**Dois caminhos de build do web.** `app/Dockerfile` compila dentro da imagem do
Flutter (funciona em qualquer máquina, mais lento na primeira vez);
`app/Dockerfile.prebuilt` só copia `app/build/web`. O `scripts/start.sh` escolhe
o segundo quando encontra o Flutter SDK instalado.

**Espera pelo banco no entrypoint.** Além do `depends_on: service_healthy`, o
`docker-entrypoint.sh` da API faz `pg_isready` em loop. Isso mantém o boot
confiável mesmo em versões de compose que ignoram `condition`.
