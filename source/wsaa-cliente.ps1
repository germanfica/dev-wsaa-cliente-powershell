#
# Configuracion de parametros
#
# Archivo del certificado firmante a usar:
$INCRTFIRMANTE="myCert.crt"

# Archivo de clave privada a usar:
$INPRIVATEKEY="myPriv.key" 

# ID de servicio a acceder:
$INIDSERVICIO="wsfe" 

# Archivo TRA a crear:
$OUTTRAFILEXML="myLoginTicketRequest.xml"

# Archivo CMS a crear:
$OUTCMS="myLoginTicketRequest.xml.cms" 

# WSDL del WSAA:
$URLWSAAWSDL = "https://wsaahomo.afip.gov.ar/ws/services/LoginCms?WSDL"

#
# No deberia ser necesario modificar nada a continuacion
#
# PASO 1: ARMAR EL TA
$dtNow = [System.DateTime]::Now
$xmlTA = New-Object System.XML.XMLDocument
$xmlTA.LoadXml('<loginTicketRequest><header><uniqueId></uniqueId><generationTime></generationTime><expirationTime></expirationTime></header><service></service></loginTicketRequest>')
$xmlUniqueId = $xmlTA.SelectSingleNode("//uniqueId")
$xmlGenTime = $xmlTA.SelectSingleNode("//generationTime")
$xmlExpTime = $xmlTA.SelectSingleNode("//expirationTime")
$xmlService = $xmlTA.SelectSingleNode("//service")
$xmlGenTime.InnerText = $dtNow.AddMinutes(-10).ToString("s")
$xmlExpTime.InnerText = $dtNow.AddMinutes(+10).ToString("s")
$xmlUniqueId.InnerText = $dtNow.ToString("yyMMdd")
$xmlService.InnerText = $INIDSERVICIO
$xmlTA.InnerXml | Out-File $OUTTRAFILEXML -Encoding ASCII

# PASO 2: FIRMAR CMS
openssl cms -sign -in $OUTTRAFILEXML -out $OUTCMS -signer $INCRTFIRMANTE -inkey $INPRIVATEKEY -nodetach -outform PEM

# PASO 3: INVOCAR AL WSAA
$cms = ((Get-Content $OUTCMS -Raw).Replace("-----BEGIN CMS-----","")).Replace("-----END CMS-----","")
$wsaa = New-WebServiceProxy -Uri $URLWSAAWSDL
$wsaa.loginCms($cms)
