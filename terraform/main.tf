# Define un recurso de tipo "aws_vpc" (Virtual Private Cloud) con el nombre local "main".
# Una VPC es una red virtual aislada lógicamente en la nube de AWS.
resource "aws_vpc" "main" {
  # Define el bloque de direcciones IP para la VPC en notación CIDR.
  # En este caso, la VPC tendrá un rango de 10.0.0.0 a 10.0.255.255.
  cidr_block = var.vpc_cidr #IP RPIVADA

  # Especifica la tenencia de las instancias EC2 lanzadas en esta VPC.-->recordar EC2 SERVER Q NECESTA TODOS LOS RECURSOS VIRTUALIZADOS QUE VIVEN DENTRO DE LA VPC
  # "default" significa que se ejecutarán en hardware compartido.
  instance_tenancy = "default"

  # Habilita la asignación de nombres de host DNS públicos a las instancias con IP pública.
  enable_dns_hostnames = true

  # Habilita el soporte para la resolución de DNS a través del servidor DNS de Amazon.
  enable_dns_support = true

  # Asigna etiquetas (metadata) a la VPC para facilitar su identificación y gestión.--> se tratara con variables luego
  tags = {
    Name = "main"
    env  = "dev"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id #DEPENDENCIA IMPLICITA CON EL RECURSO ANTERIOR
  #RECORDAR terraform es un codigo declarativo->nosostros le decimos lo que queremos y terraform crea la infra necesaria, no hace falta decirle como hacerlo
  tags = {
    Name = "project-igw"
  }

}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true #CUANDO SE CREE UNA INSTANCIA EC2 EN ESTA SUBRED , ASIGNALE UNA DIRECCION IP PUBLICA PARA QUE SEA ACCESIBLE DESDE INTERNET 

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public" { #CREAMOS EL RECURSO DE TIPO AWS_ROUTE_TABLE CON EL NOMBRE LOCAL PUBLIC
  #SOLO CON ESTO TENEMOS EL 10.0.0.0/16 LOCAL, PERO FALTA LA RUTA PARA EL TRAFICO QUE VA A INTERNET PUBLICO
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-route-table"
  }
}
#Destino        Target
#10.0.0.0/16    local 
#0.0.0.0/0      igw-xxxx TODO EL TRAFICO QUE NO SEA PARA LA VPC SE ENVIA A LA INTRNET POR EL GATEWAY QUE HEMOS CREADO 



resource "aws_route" "internet_access" { #CREAMOS UNA RUTA PARA EL TRAFICO QUE VA A INTERNET PUBLICO
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0" #DEFAULT ROUTE
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id      #DECIMOS QUE SUBRED QUEREMOS ASOCIAR A ESTA TABLA DE RUTAS
  route_table_id = aws_route_table.public.id #DECIMOS QUE TABLA DE RUTAS QUEREMOS ASOCIAR A ESTA SUBRED 
}





resource "aws_security_group" "ssh_sg" { #CREAMOS UN GRUPO DE SEGURIDAD PARA PERMITIR EL ACCESO SSH A LAS INSTANCIAS EC2 QUE VIVAN DENTRO DE LA VPC
  name        = "allow_ssh"              #nombre del grupo de seguirdad
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id
}
resource "aws_vpc_security_group_ingress_rule" "ssh" { #DEFINIMOS UNA REGLA DE ENTRADA PARA PERMITIR EL ACCESO SSH AL GRUPO DE SEGURIDAD QUE HEMOS CREADO ANTERIORMENTE
  security_group_id = aws_security_group.ssh_sg.id
  cidr_ipv4         = "0.0.0.0/0" #PERMITIMOS EL ACCESO DESDE CUALQUIER DIRECCION IP, PERO EN UN ENTORNO DE PRODUCCION RESTRINGIRIAMOS EL ACCESO A UN RANGO DE IPS CONCRETAS , O DIRECTAMENTE A UNA IP PUBLICA FIJA 
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" { #DEFINIMOS UNA REGLA DE SALIDA PARA PERMITIR TODO EL TRAFICO DE SALIDA DESDE LAS INSTANCIAS EC2 QUE VIVAN DENTRO DE LA VPC
  security_group_id = aws_security_group.ssh_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# Busca la AMI más reciente de Ubuntu
data "aws_ami" "ubuntu" { #utilizamos un data source para buscar la AMI mas reciente de ubuntu, muy util para no tener que actualizar el ID de la AMI cada vez que se lance una nueva version de ubuntu
  #buscamos (data) información de una ami (aws_ami) y guardamos el resultado en una variable local ubuntu


  most_recent = true #clave! queremos la ami que cumpla con los filtros que definimos acontinuacion

  filter {                                                               #cada filter es un criterio de busqueda, como vemos podemos definir varios filtros para acotar la busqueda
    name   = "name"                                                      #el filtro se aplica al nombre de la AMI
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] #AMI de ubuntu jammy 22.04
  }

  filter {
    name   = "virtualization-type" #tipo de virtualizacion 
    values = ["hvm"]               #HVM tipo de 
  }

  owners = ["099720109477"] # Canonical es el propìetario oficial de las AMIs de ubuntu , para no usar AMIS de terceros 



}

resource "aws_instance" "web" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type # Free Tier

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.ssh_sg.id
  ]

  key_name = var.key_name # nombre de tu key pair en AWS

  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = var.instance_name
  }
}