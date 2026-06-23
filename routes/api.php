<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TiendaController;

Route::middleware('apikey')->controller(TiendaController::class)->prefix('productos')->group(function () {
    Route::get('/',        'productos');
    Route::post('/',       'productos');
    Route::put('/{id}',    'productos');
    Route::delete('/{id}', 'productos');
    Route::get('/export',  'export');
});
