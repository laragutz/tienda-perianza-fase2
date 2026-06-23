<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ApiKeyMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $apiKey = $request->header('X-API-KEY') ?? $request->query('api_key');

        if ($apiKey !== env('API_KEY')) {
            return response()->json([
                'success' => false,
                'message' => 'API Key inválida o no proporcionada.'
            ], 401);
        }

        return $next($request);
    }
}
