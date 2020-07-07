extends Node

# Constantes:
const V_ENT_MAX = 1
const VS_SAI_Y_MAX = 130
const RECT_ALT_MAX = 270
const MAX_NIVEL_POS = 434

# Variáveis:
var crt_on = 0
var auto_on = 0
var altura = 3
var area = 1
var restricao = 2
#var nivel = 0
var vazao_saida = 0
onready var Conteudo_nivel = $Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Conteudo_Nivel
export var nivel = 0 setget setNivel
# Variáveis do Controlador PID:
var I = 0        # Saída do Integrador
var P = 0        # Saída do Proporcional
var D = 0        # Saída do Derivador
var PID = 0      # Saida do PID
var Erro = 0     # Erro atual
var Eant = 0     # Erro anterior
var BP = 70      # Banda Proporcional
var Kp = 100/BP  # Ganho Proporcional
var Ki = 1.0     # Ganho Integral
var Kd = 0       # Ganho Derivativo
var Ta = 0.1     # Intervalo de amostragem ### VERIFICAR COMPATIBILIDADE COM O delta
var cont = 0     # Contador de ciclos [para ajuste automático do SP]
# Called when the node enters the scene tree for the first time.
func _ready():
	$Controlador/ReferenceRect/Vazao_Entrada_VSlider.value = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var vazao
	var VS_MAX = sqrt(altura)/restricao
	var altera_SP = rand_range(0,100)
	var DSeg = 10/delta # número de ciclos para contar 10segundos
	
	Ta = delta
	cont += 1
	if (crt_on==1 && auto_on==0 && cont>=DSeg):
		cont = 0
		# altera o SP aleatoriamente (se a planta estiver ligada e no Manual):
		$Controlador/ReferenceRect/SetPoint_VSlider.value = rand_range(0,100)
	
	Erro = $Controlador/ReferenceRect/SetPoint_VSlider.value - $Controlador/ReferenceRect/ProgressBar.value
	if (crt_on && auto_on):  # Ligado no modo automático
		I += Ki*(Erro+Eant)*delta/2.0 # Integral
		# Limita a sída do Integrador:
		if I>100:
			I = 100
		elif I<0:
			I = 0
		P = Kp*Erro                   # Proporcional
		D = Kd*(Erro-Eant)/delta      # Derivativo
		Eant = Erro                   # Atualiza Erro anterior
		PID = P+I+D
		# Limita o PID:
		if PID>100:
			PID = 100
		elif I<0:
			I = 0
		$Controlador/ReferenceRect/Vazao_Entrada_VSlider.value = P+I+D

	# calcula o novo nível:
	vazao_saida = sqrt(nivel)/restricao
	$Planta_Nivel/Vazao_saida.value = VS_SAI_Y_MAX*vazao_saida/VS_MAX
	$Manometro_ponteiro.rotation_degrees =  $Controlador/ReferenceRect/Vazao_Entrada_VSlider.value*0.01*270*crt_on
	vazao = $Controlador/ReferenceRect/Vazao_Entrada_VSlider.value*0.01*V_ENT_MAX*crt_on - vazao_saida
	self.nivel = clamp( nivel + vazao*delta/area, 0, altura)
	$Controlador/ReferenceRect/ProgressBar.value = 100*nivel/altura
#	$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Conteudo_Nivel.region_rect.size.y = 100*nivel/altura
#	if Conteudo_nivel:
#		Conteudo_nivel.region_rect.size.y = MAX_NIVEL_POS*self.nivel/altura

func setNivel(value:float):
	nivel = value
	if Conteudo_nivel:
		Conteudo_nivel.region_rect.size.y = MAX_NIVEL_POS*0.91*value/altura # ajuste de 91% para coincidir com 100%


func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		crt_on = 1
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/TextureButton.pressed = true
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 90*auto_on
	else:
		crt_on = 0
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/TextureButton.pressed = false
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 30

func _on_btn_On_Off_toggled(button_pressed):
	if button_pressed:
		crt_on = 1
		$Controlador/ReferenceRect/btn_On_Off.pressed = true
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 90*auto_on
	else:
		crt_on = 0
		$Controlador/ReferenceRect/btn_On_Off.pressed = false
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 30


func _on_btn_Man_Auto_toggled(button_pressed):
	if button_pressed:
		auto_on = 1 	# modo Automático
		$Controlador/ReferenceRect/Vazao_Entrada_VSlider.editable = false
		$Controlador/ReferenceRect/SetPoint_VSlider.editable = true
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 60*crt_on+30
	else:
		auto_on = 0 	# modo Manual
		$Controlador/ReferenceRect/Vazao_Entrada_VSlider.editable = true
		$Controlador/ReferenceRect/SetPoint_VSlider.editable = false
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 0 + (1-crt_on)*30


func _on_TextureButton_toggled(button_pressed):
	if button_pressed:
		crt_on = 1
		$Controlador/ReferenceRect/btn_On_Off.pressed = true
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 90*auto_on
	else:
		crt_on = 0
		$Controlador/ReferenceRect/btn_On_Off.pressed = false
		$Planta_Nivel/ParallaxBackground/ParallaxLayer/Planta/Chave_Seletora/btn_seleciona.rotation_degrees = 30
