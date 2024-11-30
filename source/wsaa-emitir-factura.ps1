# Parametros básicos
$Token = "TOKEN_OBTENIDO"
$Sign = "SIGN_OBTENIDO"
$Cuit = "CUIT_DEL_EMISOR"
$WsfeWsdl = "https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"

# Crear el cliente SOAP
$wsfev1 = New-WebServiceProxy -Uri $WsfeWsdl -Namespace "AFIP.WSFE" -UseDefaultCredential

# Crear el encabezado de autenticación como un objeto del tipo esperado
$AuthHeader = New-Object AFIP.WSFE.FEAuthRequest
$AuthHeader.Token = $Token
$AuthHeader.Sign = $Sign
$AuthHeader.Cuit = [int64]$Cuit # CUIT debe ser un entero largo

# Crear el cuerpo de la solicitud como XML
$xmlBody = New-Object System.Xml.XmlDocument
$xmlBody.LoadXml(@"
<FECAERequest>
    <FeCabReq>
        <CantReg>1</CantReg>
        <PtoVta>1</PtoVta>
        <CbteTipo>11</CbteTipo> <!-- Factura C -->
    </FeCabReq>
    <FeDetReq>
        <FECAEDetRequest>
            <Concepto>1</Concepto> <!-- Productos -->
            <DocTipo>99</DocTipo> <!-- Consumidor Final -->
            <DocNro>0</DocNro> <!-- Sin DNI -->
            <CbteDesde>1</CbteDesde>
            <CbteHasta>1</CbteHasta>
            <CbteFch>$(Get-Date -Format yyyyMMdd)</CbteFch>
            <ImpTotal>121.00</ImpTotal>
            <ImpTotConc>0.00</ImpTotConc>
            <ImpNeto>100.00</ImpNeto>
            <ImpOpEx>0.00</ImpOpEx>
            <ImpTrib>0.00</ImpTrib>
            <ImpIVA>21.00</ImpIVA>
            <MonId>PES</MonId>
            <MonCotiz>1.00</MonCotiz>
            <Iva>
                <AlicIva>
                    <Id>5</Id> <!-- 21% IVA -->
                    <BaseImp>100.00</BaseImp>
                    <Importe>21.00</Importe>
                </AlicIva>
            </Iva>
        </FECAEDetRequest>
    </FeDetReq>
</FECAERequest>
"@)

# Enviar la solicitud
try {
    $response = $wsfev1.FECAESolicitar($AuthHeader, $xmlBody.DocumentElement)
    $response.FeDetResp.FECAEDetResponse
} catch {
    Write-Error $_.Exception.Message
}
