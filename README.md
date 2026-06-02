# LogLady

LogLady collects Docker container logs, stores unique log entries in PostgreSQL, and sends each unique entry to an inference server for LLM analysis. Duplicate log lines are counted on the original record and are not analyzed again.

```
                                  *:-#*##*+- +                                  
                                :====**##**=:: *                                
                              :-===---=-::----::-                               
                             =*==-----:...:--+*=--*                             
                            ***+-:..       .---**=--                            
                           %++*-:=+=:  .=*=-=-==%@*=                            
                           %++@=+*=*===+=+*#----@###=                           
                           +*#*--+-- . +::--:.-:#*%--                           
                          %+*%+-..   . :=    -.-+%%*-                           
                         @#*+#%*:  --+-+:=-:.:--*%+%*                           
                         @#*-=%@--.. .-:. ..:::-=%++*                           
                          #=*#%@+:.  .::.  ...:-@%*#=-                          
                         %#=#%#%@: .::::--: .:-@%=++=*                          
                          %+*-*=@+:..    . .:-*@#*##*%                          
                            ##%%%@#-.  ...:-+**@@%%#*                           
                               #@@@@%+=====+*#%@@@#                             
                             ##%%%*%@@%*==+#%%#@@@@%-#                          
                    %::+###=+=#--#=-@@@@@@@@@@@-%%%%##*%#*.#                    
                 %+--==*%#+-*#*#+%=--*@@@@@@@#-**=+-#==%#*#-::#  =---.%         
                *+##+=*-+#*=+:%#*%-=++**@%@%++++#:..:--*#%#*-*#-+--=--:.@       
              @ :#=#-#-+#*++# -:*-=-+-=+#@##%%#*%-..:-=%##*----=:+-:--:.-=      
             %-=+-#-#*-+**=%+#-.:.--=+@@%@@%%%%+#+%%%#@%#-=---   ..:.-.---.     
            *=+.-*#*%*@-#*=%-=#*++-+-#%**%@+++=*##%%  :=---:.  ::=:--...:= :    
          *:--:--%%#%%%%%*%%#%#%++%+#+##@@*%+*#+:-=--::*-.-= .-:-. :. ..::++-   
        %%=.==@#*#%%@@@@##%@%#%#=:#*==#-+-*#=   :.-==-:-.. :=+- ...:.:-*+**%    
       *+.-=-==#@%%@%@@%#%%@@#%*@@@@=#--*      +*=*+*--- :-:--=*-:-=**=##       
     %*@*--=-*-+%@%@@@@#@@%@+*%@#*##=:      :-=+=++:-@----:---=-***+%@#%#       
    =%--.-=%*#@##%*@@@%%%*#%+-*---.        -===+*+*+=%:--..*:==#=@@%%#**@#      
  %#@*%%*%+##--#.-::--=%#=#-.:%#==       -+-:=-:=+**+--+:-:-%%+%%%%#+#+-=%*%    
@=@#*+@::-.-#==+#=%*%++##%@##-*-++....:*+-:-.-.*+=+#==*-#-*####+**#@@###@+*+%   
#%%@%=%%%%@#-*%%#*+%#=%-%+*-##%%%@%-     ..=.: *++@--=#=#+*#@+@%%@@@@%=+*=---#  
%*%@@%%%@%%%%%%*#%+#%:++:==#@##+%#+@%-    .=-.:*+*%..+==#%*#@@@@%@@@%@@:-=++-+# 
-%@+%@%%%%%%*-##*#-+*===*++=*%##...  .      :*-::-%#**-+*%%@#@%% #@#---- +.*-=%%
```

## Requirements

- Ruby 3.3.11
- Rails 8.1.3
- PostgreSQL 18
- Redis 8
- Docker and Docker Compose

## Setup

Copy `.env.example` to `.env` and set the inference server values:

```sh
INFERENCE_URL=https://your-inference-server.example/analyze
INFERENCE_API_KEY=your-api-key
INFERENCE_MODEL=log-analyzer
INFERENCE_FALLBACK_MODEL=backup-model
```

Set `INFERENCE_FALLBACK_MODEL` to retry analysis with a second model when the server reports the primary model is unavailable (HTTP 404/410, or 400/422/503 with a model-related error).

Edit the LLM prompt at **Settings** in the running app (stored in the database). On first boot, the app seeds from `config/inference_prompt.example.txt`. Override with `INFERENCE_PROMPT` (inline) or `INFERENCE_PROMPT_FILE` (path) in the environment if needed. The inference server should return JSON with `classification`, `urgency`, `needs_action`, `fixes`, and `other_suggestions` — see the example prompt for the expected schema.

Do not commit `.env`; API keys and production secrets must live outside the repository.

## Running Locally

Start the development stack:

```sh
docker compose -f docker-compose.dev.yml up
```

The app listens on `http://localhost:3000`. Web runs `db:migrate` once at startup; Sidekiq waits for Web to pass its health check before starting, so migrations never run concurrently. The dev PostgreSQL and Redis containers use the `loglady-` prefix and host ports `15432` and `16379` so they do not collide with other projects.

Sidekiq discovers containers through the mounted Docker socket (`/var/run/docker.sock`), upserts them into the database, and imports their logs on a recurring schedule (default: every minute). Set `DOCKER_GID` in `.env` to the host docker group GID (`stat -c '%g' /var/run/docker.sock` on Linux, `stat -f '%g'` on macOS) so the Sidekiq process can access the socket.

The dev, test, and lint stacks use the official `ruby:3.3.11` image with this repository bind-mounted into the container. They run `bundle check || bundle install` against a cached Bundler volume, so Gemfile changes do not require rebuilding a tool image.

## Ingesting Logs

Log import runs automatically in Sidekiq when `DOCKER_LOG_SYNC_ENABLED=true` (the default). You can also import manually for one container:

```sh
docker compose -f docker-compose.dev.yml run --rm web ./bin/rails docker_logs:import CONTAINER=container-name
```

You can also post logs directly:

```sh
curl -X POST http://localhost:3000/log_entries \
  -H "Content-Type: application/json" \
  -d '{"log_entry":{"source_container":"web","stream":"stderr","message":"database timeout"}}'
```

Each log entry is fingerprinted by container, stream, and normalized message. When the same entry appears again, `occurrence_count` is incremented and no new analysis job is queued.

## Testing

```sh
docker compose -f docker-compose.test.yml run --rm test
```

## Linting

```sh
docker compose -f docker-compose.lint.yml run --rm rubocop
```

## Architecture

- `DockerContainer` tracks containers discovered from the Docker Engine API and import status.
- `LogEntry` stores each unique log line, duplicate count, analysis status, and LLM output.
- `LogEntries::Ingestor` creates new entries and counts duplicates.
- `DockerContainers::Synchronizer` lists containers via the Docker socket and upserts local records.
- `DockerLogs::Importer` reads container logs through the Docker Engine API and sends them through the ingestor.
- `SyncDockerContainersJob` and `ImportDockerLogsJob` run in Sidekiq on the `ingestion` queue (scheduled via sidekiq-cron).
- `AnalyzeLogEntryJob` runs in Sidekiq on the `analysis` queue.
- `Inference::Client` calls the configured inference server with the API key from the environment.

## CI and Images

GitHub Actions runs Docker-based tests and linting. The Docker publish workflow builds and publishes an image to GitHub Container Registry on push: `latest` on `main` and `v*` release tags, `staging` on the `staging` branch, plus branch name, version tag, and commit SHA tags.
