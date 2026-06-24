<?php

namespace App\Exports;

use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ProductosExport implements FromCollection, WithHeadings, WithStyles
{
    protected $filtros;

    public function __construct($filtros = [])
    {
        $this->filtros = $filtros;
    }

    public function collection()
    {
        $data = DB::select('SELECT * FROM sp_productos_get(?, ?, ?, ?)', [
            $this->filtros['buscar']       ?? null,
            $this->filtros['categoria']    ?? null,
            $this->filtros['fecha_inicio'] ?? null,
            $this->filtros['fecha_fin']    ?? null,
        ]);

        return collect($data)->map(fn($p) => [
            $p->id,
            $p->nombre,
            $p->sku,
	    $p->categoria,
	    $p->marca,
	    $p->codigo_barras,
            number_format($p->precio, 2),
            $p->stock,
            $p->activo ? 'Sí' : 'No',
            $p->fecha_registro,
        ]);
    }

    public function headings(): array
    {
        return ['ID', 'Nombre', 'SKU', 'Categoría', 'Marca', 'Código de Barras', 'Precio', 'Stock', 'Activo', 'Fecha Registro'];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => [
                'font' => ['bold' => true, 'color' => ['argb' => 'FFFFFFFF']],
                'fill' => ['fillType' => 'solid', 'startColor' => ['argb' => 'FF4F46E5']],
            ],
        ];
    }
}
