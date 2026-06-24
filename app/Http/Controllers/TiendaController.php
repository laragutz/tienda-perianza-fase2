<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Exports\ProductosExport;
use Maatwebsite\Excel\Facades\Excel;
use Exception;

/**
 * @OA\Info(
 *     title="Tienda Perianza API",
 *     version="1.0.0",
 *     description="API REST para administración de productos - Evaluación Técnica"
 * )
 * @OA\Server(
 *     url="http://143.244.188.9",
 *     description="Servidor VPS"
 * )
 * @OA\SecurityScheme(
 *     securityScheme="ApiKeyAuth",
 *     type="apiKey",
 *     in="header",
 *     name="X-API-KEY"
 * )
 */
class TiendaController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/productos",
     *     summary="Consultar productos",
     *     tags={"Productos"},
     *     security={{"ApiKeyAuth":{}}},
     *     @OA\Parameter(name="buscar", in="query", required=false, @OA\Schema(type="string")),
     *     @OA\Parameter(name="categoria", in="query", required=false, @OA\Schema(type="string")),
     *     @OA\Parameter(name="fecha_inicio", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="fecha_fin", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Response(response=200, description="Consulta exitosa"),
     *     @OA\Response(response=401, description="API Key inválida"),
     *     @OA\Response(response=500, description="Error del servidor")
     * )
     * @OA\Post(
     *     path="/api/productos",
     *     summary="Crear producto",
     *     tags={"Productos"},
     *     security={{"ApiKeyAuth":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"nombre","sku","categoria","precio","stock"},
     *             @OA\Property(property="nombre", type="string"),
     *             @OA\Property(property="sku", type="string"),
     *             @OA\Property(property="categoria", type="string"),
     *             @OA\Property(property="precio", type="number"),
     *             @OA\Property(property="stock", type="integer"),
     *             @OA\Property(property="activo", type="boolean")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Registro guardado"),
     *     @OA\Response(response=401, description="API Key inválida"),
     *     @OA\Response(response=422, description="Error de validación")
     * )
     * @OA\Put(
     *     path="/api/productos/{id}",
     *     summary="Actualizar producto",
     *     tags={"Productos"},
     *     security={{"ApiKeyAuth":{}}},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="nombre", type="string"),
     *             @OA\Property(property="sku", type="string"),
     *             @OA\Property(property="categoria", type="string"),
     *             @OA\Property(property="precio", type="number"),
     *             @OA\Property(property="stock", type="integer"),
     *             @OA\Property(property="activo", type="boolean")
     *         )
     *     ),
     *     @OA\Response(response=200, description="Registro actualizado"),
     *     @OA\Response(response=401, description="API Key inválida"),
     *     @OA\Response(response=422, description="Error de validación")
     * )
     * @OA\Delete(
     *     path="/api/productos/{id}",
     *     summary="Eliminar producto (borrado lógico)",
     *     tags={"Productos"},
     *     security={{"ApiKeyAuth":{}}},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="Registro eliminado"),
     *     @OA\Response(response=401, description="API Key inválida"),
     *     @OA\Response(response=422, description="ID requerido")
     * )
     */
    public function productos(Request $request, $id = null)
    {
        try {

            $method = $request->method();

            /*
            |--------------------------------------------------------------------------
            | GET - CONSULTAR
            |--------------------------------------------------------------------------
            */
            if ($method === 'GET') {

                $buscar       = $request->input('buscar');
                $categoria    = $request->input('categoria');
                $fechaInicio  = $request->input('fecha_inicio');
                $fechaFin     = $request->input('fecha_fin');
$ordenarPor   = $request->input('ordenar_por', 'id');
$direccion    = $request->input('direccion', 'asc');

$ordenesPermitidos = ['id', 'nombre', 'precio', 'stock'];
$direccionesPermitidas = ['asc', 'desc'];

if (!in_array($ordenarPor, $ordenesPermitidos)) {
    $ordenarPor = 'id';
}

if (!in_array($direccion, $direccionesPermitidas)) {
    $direccion = 'asc';
}

$data = DB::select('SELECT * FROM sp_productos_get(?, ?, ?, ?, ?, ?)', [
    $buscar,
    $categoria,
    $fechaInicio,
    $fechaFin,
    $ordenarPor,
    $direccion
]);

                return response()->json([
                    'success' => true,
                    'message' => count($data) > 0
                        ? 'Información consultada correctamente.'
                        : 'No se encontraron registros.',
                    'data' => $data
                ], 200);
            }

            /*
            |--------------------------------------------------------------------------
            | POST / PUT / DELETE - MERGE
            |--------------------------------------------------------------------------
            */
            if (in_array($method, ['POST', 'PUT', 'DELETE'])) {

                $delete = false;

                if ($method === 'DELETE') {
                    $delete = true;
                }

                /*
                |--------------------------------------------------------------------------
                | Validación para DELETE
                |--------------------------------------------------------------------------
                */
                if ($method === 'DELETE' && !$id) {
                    return response()->json([
                        'success' => false,
                        'message' => 'El identificador del registro es obligatorio.'
                    ], 422);
                }

                /*
                |--------------------------------------------------------------------------
                | Validación para POST / PUT
                |--------------------------------------------------------------------------
                */
                if (in_array($method, ['POST', 'PUT'])) {

                    if (!$request->filled('nombre')) {
                        return response()->json([
                            'success' => false,
                            'message' => 'El nombre del producto es obligatorio.'
                        ], 422);
                    }

                    if (!$request->filled('sku')) {
                        return response()->json([
                            'success' => false,
                            'message' => 'El SKU es obligatorio.'
                        ], 422);
                    }

                    if (!$request->filled('categoria')) {
                        return response()->json([
                            'success' => false,
                            'message' => 'La categoría es obligatoria.'
                        ], 422);
                    }

                    if (!$request->filled('precio') || $request->input('precio') <= 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'El precio debe ser mayor a 0.'
                        ], 422);
                    }

                    if (!$request->filled('stock') || $request->input('stock') < 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'El stock no puede ser negativo.'
                        ], 422);
                    }
                }

                /*
                |--------------------------------------------------------------------------
                | JSON que se enviará al procedimiento
                |--------------------------------------------------------------------------
                */
                $payload = $request->all();

                if ($method === 'DELETE') {
                    $payload = ['id' => (int)$id];
                }

                if ($method === 'POST' && !isset($payload['activo'])) {
                    $payload['activo'] = true;
                }

                $result = DB::selectOne('SELECT sp_productos(?::JSON, ?::BOOLEAN)', [
                    json_encode($payload),
                    $delete ? 'true' : 'false'
                ]);

                $msg = $result->sp_productos;

                /*
                |--------------------------------------------------------------------------
                | Mensaje según método
                |--------------------------------------------------------------------------
                */
                $message = 'Operación realizada correctamente.';

                if ($method === 'POST') {
                    $message = 'Registro guardado correctamente.';
                }

                if ($method === 'PUT') {
                    $message = 'Registro actualizado correctamente.';
                }

                if ($method === 'DELETE') {
                    $message = 'Registro eliminado correctamente.';
                }

                if (str_starts_with($msg, 'ERROR')) {
                    return response()->json([
                        'success' => false,
                        'message' => $msg
                    ], 400);
                }

                return response()->json([
                    'success' => true,
                    'message' => $message
                ], 200);
            }

            return response()->json([
                'success' => false,
                'message' => 'Método no permitido.'
            ], 405);

        } catch (Exception $e) {

            return response()->json([
                'success' => false,
                'message' => 'Ocurrió un error al procesar la solicitud.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * @OA\Get(
     *     path="/api/productos/export",
     *     summary="Exportar productos a Excel",
     *     tags={"Productos"},
     *     security={{"ApiKeyAuth":{}}},
     *     @OA\Parameter(name="buscar", in="query", required=false, @OA\Schema(type="string")),
     *     @OA\Parameter(name="categoria", in="query", required=false, @OA\Schema(type="string")),
     *     @OA\Parameter(name="fecha_inicio", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="fecha_fin", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Response(response=200, description="Archivo Excel generado"),
     *     @OA\Response(response=401, description="API Key inválida"),
     *     @OA\Response(response=500, description="Error al exportar")
     * )
     */
    public function export(Request $request)
    {
        try {

            $filtros = $request->only(['buscar', 'categoria', 'fecha_inicio', 'fecha_fin']);

            return Excel::download(new ProductosExport($filtros), 'productos.xlsx');

        } catch (Exception $e) {

            return response()->json([
                'success' => false,
                'message' => 'Error al exportar.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}
