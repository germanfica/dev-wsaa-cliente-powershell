# Parametros básicos
$Token = "TOKEN_OBTENIDO"
$Sign = "SIGN_OBTENIDO"
$Cuit = "CUIT_DEL_EMISOR"
$WsfeWsdl = "https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"

# Crear el cliente SOAP para wsfev1
$wsfev1 = New-WebServiceProxy -Uri $WsfeWsdl -Namespace "AFIP.WSFE" -UseDefaultCredential

# Configurar el encabezado de autenticación
$AuthHeader = New-Object AFIP.WSFE.ServiceSoapHeader
$AuthHeader.Token = $Token
$AuthHeader.Sign = $Sign
$AuthHeader.Cuit = $Cuit
$wsfev1.ServiceSoapHeaderValue = $AuthHeader

# Solicitar CAE para una factura C
$Comprobante = @{
    FeCAEReq = @{
        FeCabReq = @{
            CantReg = 1;
            PtoVta = 1;
            CbteTipo = 11;  # Factura C
        };
        FeDetReq = @{
            FECAEDetRequest = @(
                @{
                    Concepto = 1; # Productos
                    DocTipo = 99; # Consumidor Final
                    DocNro = 0;  # Sin DNI
                    CbteDesde = 1;
                    CbteHasta = 1;
                    CbteFch = (Get-Date).ToString("yyyyMMdd");
                    ImpTotal = 121.00;
                    ImpTotConc = 0.00;
                    ImpNeto = 100.00;
                    ImpOpEx = 0.00;
                    ImpTrib = 0.00;
                    ImpIVA = 21.00;
                    MonId = "PES";
                    MonCotiz = 1.00;
                    Iva = @{
                        AlicIva = @(
                            @{
                                Id = 5; # 21% IVA
                                BaseImp = 100.00;
                                Importe = 21.00;
                            }
                        );
                    }
                }
            )
        }
    }
}

# Enviar la solicitud
try {
    $response = $wsfev1.FECAESolicitar($Comprobante)
    $response.FeDetResp.FECAEDetResponse
} catch {
    Write-Error $_.Exception.Message
}
