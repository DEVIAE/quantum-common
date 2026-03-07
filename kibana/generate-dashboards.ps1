# generate-dashboards.ps1
# Generates Kibana dashboards in Elastic Cloud Serverless-compatible format
# Uses the exact structure validated by export from Kibana Cloud

$ErrorActionPreference = "Stop"

# ======================== HELPER FUNCTIONS ========================

function New-MetricPanel {
    param(
        [string]$panelId,
        [string]$title,
        [string]$dataViewId,
        [string]$query = "",
        [string]$color = $null,
        [int]$x, [int]$y, [int]$w = 16, [int]$h = 6
    )
    $viz = [ordered]@{ layerId = "layer-$panelId"; layerType = "data"; metricAccessor = "m1" }
    if ($color) { $viz["color"] = $color }

    return [ordered]@{
        type             = "lens"
        embeddableConfig = [ordered]@{
            syncColors = $false; syncCursor = $true; syncTooltips = $false
            filters = @(); query = [ordered]@{ query = ""; language = "kuery" }
            attributes = [ordered]@{
                title = ""; visualizationType = "lnsMetric"; type = "lens"
                references = @(
                    [ordered]@{ type = "index-pattern"; id = $dataViewId; name = "indexpattern-datasource-layer-layer-$panelId" }
                )
                state = [ordered]@{
                    visualization = $viz
                    query = [ordered]@{ query = $query; language = "kuery" }
                    filters = @()
                    datasourceStates = [ordered]@{
                        formBased    = [ordered]@{
                            layers = [ordered]@{
                                "layer-$panelId" = [ordered]@{
                                    columns = [ordered]@{
                                        m1 = [ordered]@{
                                            label = $title; dataType = "number"
                                            operationType = "count"; isBucketed = $false
                                            sourceField = "___records___"
                                            params = [ordered]@{ emptyAsNull = $true }
                                        }
                                    }
                                    columnOrder = @("m1"); sampling = 1
                                    ignoreGlobalFilters = $false; incompleteColumns = [ordered]@{}
                                }
                            }
                        }
                        indexpattern = [ordered]@{ layers = [ordered]@{} }
                        textBased    = [ordered]@{ layers = [ordered]@{} }
                    }
                    internalReferences = @(); adHocDataViews = [ordered]@{}
                }
            }
        }
        panelIndex       = $panelId
        gridData         = [ordered]@{ x = $x; y = $y; w = $w; h = $h; i = $panelId }
    }
}

function New-XYPanel {
    param(
        [string]$panelId,
        [string]$title,
        [string]$dataViewId,
        [string]$seriesType,
        [string]$query = "",
        [hashtable[]]$columns,
        [string[]]$columnOrder,
        [hashtable]$vizConfig,
        [int]$x, [int]$y, [int]$w = 24, [int]$h = 12
    )
    $layerId = "layer-$panelId"

    $colHash = [ordered]@{}
    foreach ($col in $columns) {
        $colHash[$col.id] = [ordered]@{}
        foreach ($key in $col.Keys) {
            if ($key -ne "id") { $colHash[$col.id][$key] = $col[$key] }
        }
    }

    $layer = [ordered]@{
        layerId = $layerId; layerType = "data"; seriesType = $seriesType
    }
    if ($vizConfig.accessors) { $layer["accessors"] = $vizConfig.accessors }
    if ($vizConfig.xAccessor) { $layer["xAccessor"] = $vizConfig.xAccessor }
    if ($vizConfig.splitAccessor) { $layer["splitAccessor"] = $vizConfig.splitAccessor }
    $layer["showGridlines"] = $false

    $visualization = [ordered]@{
        preferredSeriesType = $seriesType
        layers              = @($layer)
    }
    if ($vizConfig.legend) { $visualization["legend"] = $vizConfig.legend }
    else { $visualization["legend"] = [ordered]@{ isVisible = $true; position = "right" } }
    if ($vizConfig.valueLabels) { $visualization["valueLabels"] = $vizConfig.valueLabels }
    else { $visualization["valueLabels"] = "hide" }

    return [ordered]@{
        type             = "lens"
        embeddableConfig = [ordered]@{
            syncColors = $false; syncCursor = $true; syncTooltips = $false
            filters = @(); query = [ordered]@{ query = ""; language = "kuery" }
            attributes = [ordered]@{
                title = ""; visualizationType = "lnsXY"; type = "lens"
                references = @(
                    [ordered]@{ type = "index-pattern"; id = $dataViewId; name = "indexpattern-datasource-layer-$layerId" }
                )
                state = [ordered]@{
                    visualization = $visualization
                    query = [ordered]@{ query = $query; language = "kuery" }
                    filters = @()
                    datasourceStates = [ordered]@{
                        formBased    = [ordered]@{
                            layers = [ordered]@{
                                $layerId = [ordered]@{
                                    columns = $colHash
                                    columnOrder = $columnOrder
                                    sampling = 1; ignoreGlobalFilters = $false
                                    incompleteColumns = [ordered]@{}
                                }
                            }
                        }
                        indexpattern = [ordered]@{ layers = [ordered]@{} }
                        textBased    = [ordered]@{ layers = [ordered]@{} }
                    }
                    internalReferences = @(); adHocDataViews = [ordered]@{}
                }
            }
        }
        panelIndex       = $panelId
        gridData         = [ordered]@{ x = $x; y = $y; w = $w; h = $h; i = $panelId }
    }
}

function New-PiePanel {
    param(
        [string]$panelId,
        [string]$title,
        [string]$dataViewId,
        [string]$shape = "donut",
        [hashtable[]]$columns,
        [string[]]$columnOrder,
        [string[]]$primaryGroups,
        [string[]]$metrics,
        [int]$x, [int]$y, [int]$w = 16, [int]$h = 14
    )
    $layerId = "layer-$panelId"

    $colHash = [ordered]@{}
    foreach ($col in $columns) {
        $colHash[$col.id] = [ordered]@{}
        foreach ($key in $col.Keys) {
            if ($key -ne "id") { $colHash[$col.id][$key] = $col[$key] }
        }
    }

    return [ordered]@{
        type             = "lens"
        embeddableConfig = [ordered]@{
            syncColors = $false; syncCursor = $true; syncTooltips = $false
            filters = @(); query = [ordered]@{ query = ""; language = "kuery" }
            attributes = [ordered]@{
                title = ""; visualizationType = "lnsPie"; type = "lens"
                references = @(
                    [ordered]@{ type = "index-pattern"; id = $dataViewId; name = "indexpattern-datasource-layer-$layerId" }
                )
                state = [ordered]@{
                    visualization = [ordered]@{
                        shape  = $shape
                        layers = @(
                            [ordered]@{
                                layerId = $layerId; layerType = "data"
                                primaryGroups = $primaryGroups; metrics = $metrics
                                numberDisplay = "percent"; categoryDisplay = "default"
                                legendDisplay = "default"
                            }
                        )
                    }
                    query = [ordered]@{ query = ""; language = "kuery" }
                    filters = @()
                    datasourceStates = [ordered]@{
                        formBased    = [ordered]@{
                            layers = [ordered]@{
                                $layerId = [ordered]@{
                                    columns = $colHash
                                    columnOrder = $columnOrder
                                    sampling = 1; ignoreGlobalFilters = $false
                                    incompleteColumns = [ordered]@{}
                                }
                            }
                        }
                        indexpattern = [ordered]@{ layers = [ordered]@{} }
                        textBased    = [ordered]@{ layers = [ordered]@{} }
                    }
                    internalReferences = @(); adHocDataViews = [ordered]@{}
                }
            }
        }
        panelIndex       = $panelId
        gridData         = [ordered]@{ x = $x; y = $y; w = $w; h = $h; i = $panelId }
    }
}

function New-DatatablePanel {
    param(
        [string]$panelId,
        [string]$title,
        [string]$dataViewId,
        [string]$query = "",
        [hashtable[]]$columns,
        [string[]]$columnOrder,
        [hashtable[]]$vizColumns,
        [int]$x, [int]$y, [int]$w = 48, [int]$h = 14
    )
    $layerId = "layer-$panelId"

    $colHash = [ordered]@{}
    foreach ($col in $columns) {
        $colHash[$col.id] = [ordered]@{}
        foreach ($key in $col.Keys) {
            if ($key -ne "id") { $colHash[$col.id][$key] = $col[$key] }
        }
    }

    return [ordered]@{
        type             = "lens"
        embeddableConfig = [ordered]@{
            syncColors = $false; syncCursor = $true; syncTooltips = $false
            filters = @(); query = [ordered]@{ query = ""; language = "kuery" }
            attributes = [ordered]@{
                title = ""; visualizationType = "lnsDatatable"; type = "lens"
                references = @(
                    [ordered]@{ type = "index-pattern"; id = $dataViewId; name = "indexpattern-datasource-layer-$layerId" }
                )
                state = [ordered]@{
                    visualization = [ordered]@{
                        layerId = $layerId; layerType = "data"
                        columns = $vizColumns
                    }
                    query = [ordered]@{ query = $query; language = "kuery" }
                    filters = @()
                    datasourceStates = [ordered]@{
                        formBased    = [ordered]@{
                            layers = [ordered]@{
                                $layerId = [ordered]@{
                                    columns = $colHash
                                    columnOrder = $columnOrder
                                    sampling = 1; ignoreGlobalFilters = $false
                                    incompleteColumns = [ordered]@{}
                                }
                            }
                        }
                        indexpattern = [ordered]@{ layers = [ordered]@{} }
                        textBased    = [ordered]@{ layers = [ordered]@{} }
                    }
                    internalReferences = @(); adHocDataViews = [ordered]@{}
                }
            }
        }
        panelIndex       = $panelId
        gridData         = [ordered]@{ x = $x; y = $y; w = $w; h = $h; i = $panelId }
    }
}

function Build-Dashboard {
    param(
        [string]$id,
        [string]$title,
        [string]$description,
        [array]$panels,
        [bool]$timeRestore = $true,
        [string]$timeFrom = "now-24h",
        [string]$timeTo = "now"
    )

    # Build references from panels
    $refs = @()
    foreach ($p in $panels) {
        $panelIdx = $p.panelIndex
        foreach ($r in $p.embeddableConfig.attributes.references) {
            $refs += [ordered]@{
                id   = $r.id
                name = "${panelIdx}:$($r.name)"
                type = $r.type
            }
        }
    }

    # Serialize panelsJSON
    $panelsJson = ($panels | ConvertTo-Json -Depth 30 -Compress)

    $dashboard = [ordered]@{
        id                   = $id
        type                 = "dashboard"
        managed              = $false
        coreMigrationVersion = "8.8.0"
        typeMigrationVersion = "10.3.0"
        attributes           = [ordered]@{
            title                 = $title
            description           = $description
            kibanaSavedObjectMeta = [ordered]@{
                searchSourceJSON = '{"query":{"query":"","language":"kuery"},"filter":[]}'
            }
            optionsJSON           = '{"hidePanelTitles":false,"hidePanelBorders":false,"useMargins":true,"autoApplyFilters":true,"syncColors":false,"syncCursor":true,"syncTooltips":false}'
            panelsJSON            = $panelsJson
            timeRestore           = $timeRestore
            timeFrom              = $timeFrom
            timeTo                = $timeTo
        }
        references           = $refs
    }

    return ($dashboard | ConvertTo-Json -Depth 30 -Compress)
}

function Save-NdjsonFile {
    param([string]$filePath, [string]$content)
    [System.IO.File]::WriteAllText($filePath, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  Saved: $filePath ($($content.Length) chars)"
}

# ======================== COMMON COLUMN DEFINITIONS ========================

function Col-Count {
    param([string]$id = "m1", [string]$label = "Count")
    return @{ id = $id; label = $label; dataType = "number"; operationType = "count"
        isBucketed = $false; sourceField = "___records___"; params = @{ emptyAsNull = $true } 
    }
}

function Col-DateHistogram {
    param([string]$id = "d1", [string]$field = "@timestamp", [string]$label = "@timestamp")
    return @{ id = $id; label = $label; dataType = "date"; operationType = "date_histogram"
        sourceField = $field; isBucketed = $true; params = @{ interval = "auto"; includeEmptyRows = $true; dropPartials = $false } 
    }
}

function Col-Terms {
    param([string]$id, [string]$field, [string]$label, [int]$size = 10, [string]$orderBy = "m1")
    return @{ id = $id; label = $label; dataType = "string"; operationType = "terms"
        sourceField = $field; isBucketed = $true
        params = @{ size = $size; orderBy = @{ type = "column"; columnId = $orderBy }; orderDirection = "desc" } 
    }
}

function Col-Average {
    param([string]$id, [string]$field, [string]$label)
    return @{ id = $id; label = $label; dataType = "number"; operationType = "average"
        sourceField = $field; isBucketed = $false; params = @{ emptyAsNull = $true } 
    }
}

# ======================== DASHBOARD 1: LOGS ========================

Write-Host "`n=== Generating Dashboard 1: Quantum Logs - Monitoreo ==="

$logsDV = "quantum-logs-dv"
$logsPanels = @(
    # P1: Total Logs (metric)
    (New-MetricPanel -panelId "p1" -title "Total Logs" -dataViewId $logsDV -x 0 -y 0 -w 16 -h 6)
    # P2: Errores (metric, red)
    (New-MetricPanel -panelId "p2" -title "Errores" -dataViewId $logsDV -query 'log.level : "ERROR"' -color "#E7664C" -x 16 -y 0 -w 16 -h 6)
    # P3: Warnings (metric, yellow)
    (New-MetricPanel -panelId "p3" -title "Warnings" -dataViewId $logsDV -query 'log.level : "WARN"' -color "#F1D86F" -x 32 -y 0 -w 16 -h 6)
    # P4: Volumen de Logs por Nivel (area_stacked)
    (New-XYPanel -panelId "p4" -title "Volumen de Logs por Nivel" -dataViewId $logsDV -seriesType "area_stacked" `
        -columns @(
        (Col-DateHistogram -id "d1" -field "@timestamp")
        (Col-Terms -id "b1" -field "log.level" -label "Level")
        (Col-Count -id "m1")
    ) -columnOrder @("d1", "b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "d1"; splitAccessor = "b1"
        legend = [ordered]@{ isVisible = $true; position = "right" }
    } -x 0 -y 6 -w 32 -h 14)
    # P5: Distribucion por Nivel (donut)
    (New-PiePanel -panelId "p5" -title "Distribucion por Nivel" -dataViewId $logsDV -shape "donut" `
        -columns @(
        (Col-Terms -id "b1" -field "log.level" -label "Log Level")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "m1") -primaryGroups @("b1") -metrics @("m1") `
        -x 32 -y 6 -w 16 -h 14)
    # P6: Logs por Servicio (bar_horizontal)
    (New-XYPanel -panelId "p6" -title "Logs por Servicio" -dataViewId $logsDV -seriesType "bar_horizontal" `
        -columns @(
        (Col-Terms -id "b1" -field "serviceName" -label "Servicio")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "b1"
        legend = [ordered]@{ isVisible = $false }
        valueLabels = "show"
    } -x 0 -y 20 -w 24 -h 12)
    # P7: Errores en el Tiempo (line)
    (New-XYPanel -panelId "p7" -title "Errores en el Tiempo" -dataViewId $logsDV -seriesType "line" `
        -query 'log.level : "ERROR"' `
        -columns @(
        (Col-DateHistogram -id "d1" -field "@timestamp")
        (Col-Terms -id "b1" -field "serviceName" -label "Servicio" -size 5)
        (Col-Count -id "m1" -label "Errores")
    ) -columnOrder @("d1", "b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "d1"; splitAccessor = "b1"
        legend = [ordered]@{ isVisible = $true; position = "right" }
    } -x 24 -y 20 -w 24 -h 12)
    # P8: Top Mensajes de Error (datatable)
    (New-DatatablePanel -panelId "p8" -title "Top Mensajes de Error" -dataViewId $logsDV `
        -query 'log.level : "ERROR"' `
        -columns @(
        (Col-Terms -id "b1" -field "message" -label "Mensaje" -size 20)
        (Col-Terms -id "b2" -field "serviceName" -label "Servicio")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "b2", "m1") `
        -vizColumns @(
        [ordered]@{ columnId = "b1" }
        [ordered]@{ columnId = "b2" }
        [ordered]@{ columnId = "m1" }
    ) -x 0 -y 32 -w 48 -h 14)
)

$logsNdjson = Build-Dashboard -id "q-dash-logs" `
    -title "Quantum Logs - Monitoreo" `
    -description "Dashboard de monitoreo de logs de microservicios Quantum File Processor." `
    -panels $logsPanels

Save-NdjsonFile -filePath "$PSScriptRoot\04-dashboard-logs.ndjson" -content $logsNdjson

# ======================== DASHBOARD 2: AUDIT ========================

Write-Host "`n=== Generating Dashboard 2: Quantum Audit - Eventos ==="

$auditDV = "quantum-audit-dv"
$auditPanels = @(
    # P1: Total Eventos (metric)
    (New-MetricPanel -panelId "p1" -title "Total Eventos" -dataViewId $auditDV -x 0 -y 0 -w 16 -h 6)
    # P2: Chunks Procesados (metric)
    (New-MetricPanel -panelId "p2" -title "Chunks Procesados" -dataViewId $auditDV -query 'action : "CHUNK_PROCESSED"' -color "#54B399" -x 16 -y 0 -w 16 -h 6)
    # P3: Archivos Ingresados (metric)
    (New-MetricPanel -panelId "p3" -title "Archivos Ingresados" -dataViewId $auditDV -query 'action : "FILE_INGESTED"' -color "#6092C0" -x 32 -y 0 -w 16 -h 6)
    # P4: Eventos por Tipo en el Tiempo (area_stacked)
    (New-XYPanel -panelId "p4" -title "Eventos por Tipo" -dataViewId $auditDV -seriesType "area_stacked" `
        -columns @(
        (Col-DateHistogram -id "d1" -field "@timestamp")
        (Col-Terms -id "b1" -field "action" -label "Accion")
        (Col-Count -id "m1")
    ) -columnOrder @("d1", "b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "d1"; splitAccessor = "b1"
        legend = [ordered]@{ isVisible = $true; position = "right" }
    } -x 0 -y 6 -w 32 -h 14)
    # P5: Distribucion por Accion (donut)
    (New-PiePanel -panelId "p5" -title "Distribucion por Accion" -dataViewId $auditDV -shape "donut" `
        -columns @(
        (Col-Terms -id "b1" -field "action" -label "Accion")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "m1") -primaryGroups @("b1") -metrics @("m1") `
        -x 32 -y 6 -w 16 -h 14)
    # P6: Duracion Promedio por Accion (bar)
    (New-XYPanel -panelId "p6" -title "Duracion Promedio por Accion" -dataViewId $auditDV -seriesType "bar" `
        -columns @(
        (Col-Terms -id "b1" -field "action" -label "Accion")
        (Col-Average -id "m1" -field "durationMs" -label "Duracion Promedio (ms)")
    ) -columnOrder @("b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "b1"
        legend = [ordered]@{ isVisible = $false }
        valueLabels = "show"
    } -x 0 -y 20 -w 24 -h 12)
    # P7: Procesamiento por Servicio (bar_horizontal)
    (New-XYPanel -panelId "p7" -title "Procesamiento por Servicio" -dataViewId $auditDV -seriesType "bar_horizontal" `
        -columns @(
        (Col-Terms -id "b1" -field "serviceName" -label "Servicio")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "b1"
        legend = [ordered]@{ isVisible = $false }
        valueLabels = "show"
    } -x 24 -y 20 -w 24 -h 12)
    # P8: Ultimos Eventos (datatable)
    (New-DatatablePanel -panelId "p8" -title "Detalle de Eventos" -dataViewId $auditDV `
        -columns @(
        (Col-Terms -id "b1" -field "action" -label "Accion" -size 20)
        (Col-Terms -id "b2" -field "serviceName" -label "Servicio")
        (Col-Terms -id "b3" -field "entityId" -label "Entity ID")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "b2", "b3", "m1") `
        -vizColumns @(
        [ordered]@{ columnId = "b1" }
        [ordered]@{ columnId = "b2" }
        [ordered]@{ columnId = "b3" }
        [ordered]@{ columnId = "m1" }
    ) -x 0 -y 32 -w 48 -h 14)
)

$auditNdjson = Build-Dashboard -id "q-dash-audit" `
    -title "Quantum Audit - Eventos" `
    -description "Dashboard de eventos de auditoria del sistema Quantum File Processor." `
    -panels $auditPanels

Save-NdjsonFile -filePath "$PSScriptRoot\05-dashboard-audit.ndjson" -content $auditNdjson

# ======================== DASHBOARD 3: OVERVIEW ========================

Write-Host "`n=== Generating Dashboard 3: Quantum Overview ==="

$metricsDV = "quantum-metrics-dv"
$overviewPanels = @(
    # P1: Total Logs (metric) - from logs
    (New-MetricPanel -panelId "p1" -title "Total Logs" -dataViewId $logsDV -x 0 -y 0 -w 12 -h 6)
    # P2: Total Audit Events (metric) - from audit
    (New-MetricPanel -panelId "p2" -title "Total Eventos Audit" -dataViewId $auditDV -x 12 -y 0 -w 12 -h 6)
    # P3: Errores (metric) - from logs
    (New-MetricPanel -panelId "p3" -title "Errores" -dataViewId $logsDV -query 'log.level : "ERROR"' -color "#E7664C" -x 24 -y 0 -w 12 -h 6)
    # P4: Chunks Procesados (metric) - from audit
    (New-MetricPanel -panelId "p4" -title "Chunks Procesados" -dataViewId $auditDV -query 'action : "CHUNK_PROCESSED"' -color "#54B399" -x 36 -y 0 -w 12 -h 6)
    # P5: Volumen de Logs (area)
    (New-XYPanel -panelId "p5" -title "Volumen de Logs" -dataViewId $logsDV -seriesType "area" `
        -columns @(
        (Col-DateHistogram -id "d1" -field "@timestamp")
        (Col-Terms -id "b1" -field "log.level" -label "Level")
        (Col-Count -id "m1")
    ) -columnOrder @("d1", "b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "d1"; splitAccessor = "b1"
        legend = [ordered]@{ isVisible = $true; position = "right" }
    } -x 0 -y 6 -w 24 -h 14)
    # P6: Procesamiento de Archivos (area)
    (New-XYPanel -panelId "p6" -title "Eventos de Procesamiento" -dataViewId $auditDV -seriesType "area" `
        -columns @(
        (Col-DateHistogram -id "d1" -field "@timestamp")
        (Col-Terms -id "b1" -field "action" -label "Accion")
        (Col-Count -id "m1")
    ) -columnOrder @("d1", "b1", "m1") `
        -vizConfig @{
        accessors = @("m1"); xAccessor = "d1"; splitAccessor = "b1"
        legend = [ordered]@{ isVisible = $true; position = "right" }
    } -x 24 -y 6 -w 24 -h 14)
    # P7: Servicios Activos (donut) - from logs
    (New-PiePanel -panelId "p7" -title "Servicios Activos" -dataViewId $logsDV -shape "donut" `
        -columns @(
        (Col-Terms -id "b1" -field "serviceName" -label "Servicio")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "m1") -primaryGroups @("b1") -metrics @("m1") `
        -x 0 -y 20 -w 16 -h 12)
    # P8: Top Errores (datatable)
    (New-DatatablePanel -panelId "p8" -title "Top Errores Recientes" -dataViewId $logsDV `
        -query 'log.level : "ERROR"' `
        -columns @(
        (Col-Terms -id "b1" -field "message" -label "Mensaje" -size 10)
        (Col-Terms -id "b2" -field "serviceName" -label "Servicio")
        (Col-Count -id "m1")
    ) -columnOrder @("b1", "b2", "m1") `
        -vizColumns @(
        [ordered]@{ columnId = "b1" }
        [ordered]@{ columnId = "b2" }
        [ordered]@{ columnId = "m1" }
    ) -x 16 -y 20 -w 32 -h 12)
)

$overviewNdjson = Build-Dashboard -id "q-dash-overview" `
    -title "Quantum Overview - Sistema" `
    -description "Dashboard general del sistema Quantum File Processor con metricas de logs, audit y procesamiento." `
    -panels $overviewPanels

Save-NdjsonFile -filePath "$PSScriptRoot\06-dashboard-overview.ndjson" -content $overviewNdjson

Write-Host "`n=== All 3 dashboards generated successfully ==="
Write-Host "Files:"
Write-Host "  - 04-dashboard-logs.ndjson"
Write-Host "  - 05-dashboard-audit.ndjson"
Write-Host "  - 06-dashboard-overview.ndjson"
