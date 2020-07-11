extends Node
# Simulador de controle de nível:
# 
# Modo Automático: - controlador PID ativado
#                  - ajuste do SetPoint pelo slider SP
# Modo Manual: - ajuste da vazão de entrada pelo slider MV

# Objetos utilizados:
onready var Conteudo_nivel = $Planta_Nivel/Planta/Conteudo_Nivel
onready var MV_Slider = $Controlador/ReferenceRect/Vazao_Entrada_VSlider
onready var SP_Slider = $Controlador/ReferenceRect/SetPoint_VSlider
onready var PV_PgBar = $Controlador/ReferenceRect/ProgressBar
onready var VzSaida_PgBar = $Planta_Nivel/Vazao_saida
onready var Manometro_pt = $Manometro_ponteiro
onready var OnOff_plt_TxtBtn = $Planta_Nivel/Planta/OnOff_TextureButton
onready var btn_seleciona = $Planta_Nivel/Planta/Chave_Seletora/btn_seleciona
onready var OnOff_TxtBtn = $Controlador/ReferenceRect/btn_On_Off

# Constantes: 
#(levantamento feito na planta para determinação da curva de vazão da válvula 
# pneumática, pelos alunos de Cálculo Numérico 2018: Davi, Leonardo, Marcos e Vitor)
const V_ENT_MAX = 4000    # vazão máxima de entrada (4000 cm3/s ~~ 240 l/min)
const MAX_NIVEL_POS = 395 # valor (em pixels) correspondente ao nível máximo permitido
const ALTURA = 50  # altura máxima do nível no tanque (cm)
const AREA = 115   # área do tanque (cm^2)
const V_SAI_MAX = 0.25*V_ENT_MAX     # vazão máxima de saída (V_SAI_MAX < V_ENT_MAX)
									 # (ToDo: medir a vazão máxima real)
const REST_MIN  = sqrt(ALTURA)/V_SAI_MAX  # restrição mínima de saída,
										  # corresponde à válvula 100% aberta

# Variáveis:
var crt_on = 0   # indica se a planta está ligada=1/desligada-0
var auto_on = 0  # indica se a planta está no modo automático=1/manual=0
# Considerando inicialmente o tanque cheio e válvula de saída 100% aberta, temos:
var restricao = REST_MIN    # restrição da válvula manual de entrada (ToDo: acrescentar slider de ajuste)
var vazao_saida = V_SAI_MAX # vazão de saída (cm3/s), varia em função do nível e da restrição na saída

export var nivel = 0 setget setNivel  # nível de água no tanque
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


# Função chamada uma única vez, no início do programa:
func _ready():
	MV_Slider.value = 0


# Função chamada a cada intervalo de tempo, igual a 'delta' segundos:
# (o padrão é: delta = 1/60 segundos)
func _process(delta):
	var vazao  # vazão resultante: vazao = V_entrada - V_saida
	var DSeg = 10/delta # número de ciclos para contar 10 segundos
	
	cont += 1
	# altera o SP aleatoriamente (se a planta estiver ligada e no Manual):
	# (ToDo: retirar esta parte e transferir para a cena "Jogo")
	if (crt_on==1 && auto_on==0 && cont>=DSeg):
		cont = 0
		SP_Slider.value = rand_range(0,100)
	
	# Considerando Ta=delta, teremos um controle aproximadamente contínuo:
	Ta = delta
	Erro = SP_Slider.value - PV_PgBar.value
	if (crt_on && auto_on):  # Se estiver ligado no modo automático
		I += Ki*(Erro+Eant)*delta/2.0 # Integral
		if Ki==0: 	# zera a saída do integrador, caso Ki seja zerado
			I = 0
		# Limita a saída do Integrador:
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
		MV_Slider.value = P+I+D

	# calcula o novo nível:
	vazao_saida = sqrt(nivel)/restricao
	VzSaida_PgBar.value = 100*vazao_saida/V_SAI_MAX
	Manometro_pt.rotation_degrees =  MV_Slider.value*0.01*270*crt_on
	vazao = MV_Slider.value*0.01*V_ENT_MAX*crt_on - vazao_saida
	self.nivel = clamp( nivel + vazao*delta/AREA, 0, ALTURA)
	PV_PgBar.value = 100*nivel/ALTURA


func setNivel(value:float):
	nivel = value
	if Conteudo_nivel:
		Conteudo_nivel.region_rect.size.y = MAX_NIVEL_POS*value/ALTURA


func _on_btn_Man_Auto_toggled(button_pressed):
	if button_pressed:
		auto_on = 1 	# modo Automático
		MV_Slider.editable = false
		SP_Slider.editable = true
		btn_seleciona.rotation_degrees = 60*crt_on+30
	else:
		auto_on = 0 	# modo Manual
		MV_Slider.editable = true
		SP_Slider.editable = false
		btn_seleciona.rotation_degrees = 0 + (1-crt_on)*30


func _on_btn_On_Off_toggled(button_pressed):
	if button_pressed: # Ligado
		crt_on = 1
		OnOff_plt_TxtBtn.pressed = true
		btn_seleciona.rotation_degrees = 90*auto_on
	else:              # Desligado
		crt_on = 0
		OnOff_plt_TxtBtn.pressed = false
		btn_seleciona.rotation_degrees = 30


func _on_OnOff_TextureButton_toggled(button_pressed):
	if button_pressed: # Ligado
		crt_on = 1
		OnOff_TxtBtn.pressed = true
		btn_seleciona.rotation_degrees = 90*auto_on
	else:              # Desligado
		crt_on = 0
		OnOff_TxtBtn.pressed = false
		btn_seleciona.rotation_degrees = 30
