bash:
	docker-compose run --rm web bash

import:
	docker-compose run --rm web php App/Core/Console/execute.php Import

up:
	docker-compose up -d

run:
	@make up
	@sleep 5
	@timeout /t 5 /nobreak > nul
	@make import
