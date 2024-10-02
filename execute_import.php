<?php
// Inclua o autoload do Composer
require 'vendor/autoload.php';

// Importe a classe Import
use App\Core\Console\Commands\Import;

// Execute o método run() da classe Import
$import = new Import();
$import->run();
