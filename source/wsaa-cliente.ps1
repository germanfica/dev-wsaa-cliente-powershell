#
# Parametros de linea de comandos:
#
# $Certificado: Archivo del certificado firmante a usar
# $ClavePrivada: Archivo de clave privada a usar
# $ServicioId: ID de servicio a acceder
# $outXml: Archivo TRA a crear
# $outCms: Archivo CMS a crear
# $wsaaWsdl: URL del WSDL del WSAA
[CmdletBinding()]
Param(
   [Parameter(Mandatory=$False)]
   [string]$Certificado="myCert.crt",
	
   [Parameter(Mandatory=$False)]
   [string]$ClavePrivada="myPriv.key",
   
   [Parameter(Mandatory=$False)]
   [string]$ServicioId="wsfe",
   
   [Parameter(Mandatory=$False)]
   [string]$outXml="myLoginTicketRequest.xml",   
   
   [Parameter(Mandatory=$False)]
   [string]$outCms="myLoginTicketRequest.xml.cms",   

   [Parameter(Mandatory=$False)]
   [string]$wsaaWsdl = "https://wsaahomo.afip.gov.ar/ws/services/LoginCms?WSDL"    
)

# PASO 1: ARMAR EL TA
$dtNow = Get-Date 
$xmlTA = New-Object System.XML.XMLDocument
$xmlTA.LoadXml('<loginTicketRequest><header><uniqueId></uniqueId><generationTime></generationTime><expirationTime></expirationTime></header><service></service></loginTicketRequest>')
$xmlUniqueId = $xmlTA.SelectSingleNode("//uniqueId")
$xmlGenTime = $xmlTA.SelectSingleNode("//generationTime")
$xmlExpTime = $xmlTA.SelectSingleNode("//expirationTime")
$xmlService = $xmlTA.SelectSingleNode("//service")
$xmlGenTime.InnerText = $dtNow.AddMinutes(-10).ToString("s")
$xmlExpTime.InnerText = $dtNow.AddMinutes(+10).ToString("s")
$xmlUniqueId.InnerText = $dtNow.ToString("yyyyMMdd")
$xmlService.InnerText = $ServicioId
$seqNr = Get-Date -UFormat "%Y%m%d%H%S"
$xmlTA.InnerXml | Out-File $seqNr-$outXml -Encoding ASCII

# PASO 2: FIRMAR CMS
openssl cms -sign -in $seqNr-$outXml -out $seqNr-$outCms -signer $Certificado -inkey $ClavePrivada -nodetach -outform PEM

# PASO 3: INVOCAR AL WSAA
$cms = ((Get-Content $seqNr-$outCms -Raw).Replace("-----BEGIN CMS-----","")).Replace("-----END CMS-----","")
$wsaa = New-WebServiceProxy -Uri $wsaaWsdl
$wsaa.loginCms($cms) > $seqNr-myloginTicketResponse.xml
type $seqNr-myloginTicketResponse.xml
