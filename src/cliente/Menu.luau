--!nonstrict
-- Menú del cazador (M en el teclado, Select en el mando): bestiario e inventario.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local Compartido = ReplicatedStorage:WaitForChild("Compartido")
local Armas = require(Compartido.Armas)
local Remotos = require(Compartido.Remotos)
local Escala = require(script.Parent.Escala)

local Menu = {}
local jugador = Players.LocalPlayer
local perfil = nil
local datosBestiario = nil
local gui: ScreenGui
local ventana: Frame
local abierto = false
local pestana = "bestiario"
local elegido = 1
local alCambiar
local primerBoton

local ARENA = Color3.fromRGB(196, 160, 104)
local OSCURO = Color3.fromRGB(40, 28, 16)
local TEXTO = Color3.fromRGB(255, 244, 214)
local DORADO = Color3.fromRGB(255, 214, 120)
local COLOR_ELEMENTO = { Arena = Color3.fromRGB(230, 176, 74), Brasa = Color3.fromRGB(255, 122, 58), Sombra = Color3.fromRGB(160, 76, 224), Sol = Color3.fromRGB(255, 214, 90) }
local RANURAS = { { "cabeza", "Cabeza" }, { "torso", "Torso" }, { "brazos", "Brazos" }, { "piernas", "Piernas" } }
local NOMBRE_SET = {}
for _, f in Armas.FAMILIAS do
	NOMBRE_SET[f.set] = f.nombreSet
end

local function crear(clase, props, padre)
	local x = Instance.new(clase)
	for k, v in props do
		x[k] = v
	end
	x.Parent = padre
	return x
end

local function texto(props, padre)
	local base = { BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextColor3 = TEXTO, TextStrokeTransparency = 0, TextStrokeColor3 = OSCURO, TextSize = 16, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }
	for k, v in props do
		base[k] = v
	end
	return crear("TextLabel", base, padre)
end

local function boton(t, color, alPulsar, padre, props)
	local b = crear("TextButton", { Text = t, Font = Enum.Font.Arcade, TextSize = 14, TextColor3 = OSCURO, BackgroundColor3 = color, BorderSizePixel = 0, AutoButtonColor = true, Size = UDim2.fromOffset(150, 32), TextWrapped = true }, padre)
	crear("UIStroke", { Thickness = 2, Color = OSCURO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	for k, v in props or {} do
		b[k] = v
	end
	b.Activated:Connect(alPulsar)
	primerBoton = primerBoton or b
	return b
end

local function panel(pos, tam, padre)
	local f = crear("Frame", { Position = pos, Size = tam, BackgroundColor3 = Color3.fromRGB(150, 118, 72), BorderSizePixel = 0 }, padre)
	crear("UIStroke", { Thickness = 2, Color = OSCURO }, f)
	return f
end

local function lista(pos, tam, padre)
	local l = crear("ScrollingFrame", { Position = pos, Size = tam, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, padre)
	crear("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, l)
	return l
end

local function tiempo(seg)
	if not seg then
		return "sin registro"
	end
	return ("%d:%02d"):format(seg // 60, seg % 60)
end

local function enRefugio(): boolean
	return jugador:GetAttribute("Zona") == "refugio"
end

-- ---------- vista 3D del cazador (con su armadura y su arma) ----------
local conexionVista
local function vistaPersonaje(padre: GuiObject)
	if conexionVista then
		conexionVista:Disconnect()
		conexionVista = nil
	end
	local vista = crear("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(60, 44, 70), BorderSizePixel = 0, Ambient = Color3.fromRGB(200, 190, 180), LightColor = Color3.fromRGB(255, 240, 220), LightDirection = Vector3.new(-1, -1, -1) }, padre)
	local char = jugador.Character
	if not char then
		return
	end
	local mundo = crear("WorldModel", {}, vista)
	char.Archivable = true
	local copia = char:Clone()
	char.Archivable = false
	if not copia then
		return
	end
	for _, d in copia:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui") or d:IsA("Highlight") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = d.Name == "HumanoidRootPart"
		end
	end
	local hum = copia:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	copia.Parent = mundo
	copia:PivotTo(CFrame.new())
	local camara = crear("Camera", { FieldOfView = 40 }, vista)
	camara.CFrame = CFrame.lookAt(Vector3.new(0, 1.2, -11), Vector3.new(0, 0.6, 0))
	vista.CurrentCamera = camara
	local inicio = os.clock()
	conexionVista = game:GetService("RunService").RenderStepped:Connect(function()
		if copia.Parent then
			copia:PivotTo(CFrame.Angles(0, math.sin((os.clock() - inicio) * 0.6) * 0.9, 0))
		end
	end)
end

-- ---------- cálculo de atributos ----------
local function tiene(lista_, id)
	return perfil and table.find(lista_, id) ~= nil
end

local function atributos()
	local equipo = perfil and perfil.equipo or {}
	local lleva = {}
	local sets = {}
	for _, set in Armas.SETS do
		sets[set] = 0
	end
	for _, pieza in equipo do
		lleva[pieza] = true
		local set = Armas.PIEZA_SET[pieza]
		if set then
			sets[set] += 1
		end
	end
	local nivel = perfil and perfil.nivel or 1
	local mods = Armas.mods(lleva)
	local function m(k)
		return mods[k] or (Armas.MOD_SUMA[k] and 0 or 1)
	end
	local function pct(x)
		return math.floor((x - 1) * 100 + 0.5)
	end
	local vida = (lleva.coraza and 120 or (lleva.coraza_granito and 115 or (lleva.manto and 110 or 100))) + (nivel - 1) * 2 + m("vida")
	local reduccion = m("reduccion")
	if lleva.caparazon then
		reduccion *= 0.93
	end
	if lleva.manto then
		reduccion *= 0.97
	end
	local lineas = {
		("Vida máxima: %d"):format(vida),
		("Reducción de daño: %d%%"):format(math.floor((1 - reduccion) * 100 + 0.5)),
		("Recuperación de aguante: %s"):format(((lleva.garras and 1.35 or 1) * m("aguanteRegen") > 1) and ("+" .. pct((lleva.garras and 1.35 or 1) * m("aguanteRegen")) .. "%") or "normal"),
		("Esquivar gasta: %d de aguante"):format(math.floor((lleva.grebas and 14 or 25) * m("esquivaCosto") + 0.5)),
		("Distancia de esquiva: %s"):format(((lleva.botas_uku and 1.3 or 1) * m("esquivaLejos") > 1) and ("+" .. pct((lleva.botas_uku and 1.3 or 1) * m("esquivaLejos")) .. "%") or "normal"),
		("Esquiva perfecta: %.2f s"):format((lleva.mascara and 0.45 or 0.3) * m("ventanaEsquiva")),
		("Ataques fuertes: %s aguante"):format(lleva.guanteletes and "-30%" or "normal"),
		("Correr: %s aguante"):format(((lleva.grebas_escarabajo and 0.65 or 1) * m("correrCosto") < 1) and (pct((lleva.grebas_escarabajo and 0.65 or 1) * m("correrCosto")) .. "%") or "normal"),
	}
	if m("sinAturdir") > 0 then
		table.insert(lineas, "Inmune a los gritos de Camazotz")
	end
	if m("curaGolpe") > 0 then
		table.insert(lineas, "Cada golpe te cura 0,5 de vida")
	end
	if m("danioCabeza") > 1 then
		table.insert(lineas, ("Golpes a la cabeza: +%d%% de daño"):format(pct(m("danioCabeza"))))
	end
	if m("danioFuerte") > 1 then
		table.insert(lineas, ("Golpes fuertes: +%d%% de daño"):format(pct(m("danioFuerte"))))
	end
	if m("partes") > 1 then
		table.insert(lineas, ("Rompes partes %d%% más rápido"):format(pct(m("partes"))))
	end
	if m("aturdir") > 1 then
		table.insert(lineas, ("Derribo: +%d%%"):format(pct(m("aturdir"))))
	end
	if m("empuje") < 1 then
		table.insert(lineas, "Los empujones te mueven la mitad")
	end
	if lleva.brazales then
		table.insert(lineas, "Cada golpe te cura 0,5 de vida")
	end
	if lleva.capucha then
		table.insert(lineas, "Inmune al rugido de Sekhmaur")
	end
	if lleva.yelmo then
		table.insert(lineas, "Golpes a la cabeza: +30% de derribo")
	end
	if lleva.corona then
		table.insert(lineas, "Golpes a la cabeza: +10% de daño")
	end
	if lleva.coraza_granito then
		table.insert(lineas, "Los empujones te mueven la mitad")
	end
	if lleva.punos_piedra then
		table.insert(lineas, "Golpes fuertes: +10% de daño")
	end
	if lleva.grebas_montana then
		table.insert(lineas, "Aturdimientos y golpes duran menos")
	end
	return lineas, sets
end

-- ---------- pestañas ----------
local function limpiar()
	if conexionVista then
		conexionVista:Disconnect()
		conexionVista = nil
	end
	for _, x in ventana:GetChildren() do
		if not x:IsA("UIStroke") then
			x:Destroy()
		end
	end
	primerBoton = nil
end

local function cabecera()
	local nivel = perfil and perfil.nivel or 1
	local xp = perfil and perfil.xp or 0
	local necesita = Armas.xpParaSubir(nivel)
	texto({ Size = UDim2.fromOffset(300, 30), Position = UDim2.fromOffset(16, 12), Text = ("CAZADOR · NIVEL %d"):format(nivel), TextSize = 22, TextColor3 = DORADO }, ventana)
	local barra = crear("Frame", { Size = UDim2.fromOffset(260, 10), Position = UDim2.fromOffset(16, 44), BackgroundColor3 = Color3.fromRGB(40, 30, 20), BorderSizePixel = 0 }, ventana)
	crear("Frame", { Size = UDim2.fromScale(nivel >= Armas.NIVEL_MAX and 1 or math.clamp(xp / necesita, 0, 1), 1), BackgroundColor3 = Color3.fromRGB(127, 255, 244), BorderSizePixel = 0 }, barra)
	texto({ Size = UDim2.fromOffset(260, 18), Position = UDim2.fromOffset(282, 40), Text = nivel >= Armas.NIVEL_MAX and "nivel máximo" or ("%d / %d XP"):format(xp, necesita), TextSize = 12 }, ventana)
	local pestanas = { { "bestiario", "Bestiario" } }
	if enRefugio() then
		table.insert(pestanas, { "inventario", "Inventario" })
	end
	for i, t in pestanas do
		boton(t[2], pestana == t[1] and DORADO or ARENA, function()
			pestana = t[1]
			Menu.mostrar()
		end, ventana, { Position = UDim2.new(1, -330 + (i - 1) * 160, 0, 14) })
	end
end

local function mostrarBestiario()
	-- lista de Behemoths a la izquierda
	for i, b in Armas.BESTIARIO do
		boton((b.proximamente and "??? " or "") .. b.nombre, i == elegido and DORADO or ARENA, function()
			elegido = i
			Menu.mostrar()
		end, ventana, { Position = UDim2.fromOffset(16, 76 + (i - 1) * 44), Size = UDim2.fromOffset(190, 38) })
	end
	-- ficha a la derecha
	local b = Armas.BESTIARIO[elegido]
	local f = panel(UDim2.fromOffset(222, 76), UDim2.new(1, -238, 1, -92), ventana)
	crear("UIStroke", { Thickness = 3, Color = COLOR_ELEMENTO[b.elemento] or OSCURO }, f)
	texto({ Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 8), Text = b.nombre .. " · " .. b.titulo, TextSize = 22, TextColor3 = DORADO }, f)
	texto({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 40), Text = ("Isla: %s   ·   Naturaleza: %s   ·   Dificultad %s"):format(b.isla, b.elemento, string.rep("*", b.estrellas) .. string.rep("-", 5 - b.estrellas)), TextSize = 13 }, f)
	texto({ Size = UDim2.new(1, -20, 0, 70), Position = UDim2.fromOffset(10, 66), Text = b.descripcion, TextSize = 14 }, f)
	local partes = { "PARTES ROMPIBLES" }
	for _, p in b.partes do
		table.insert(partes, "- " .. p[1] .. (b.proximamente and "" or ("  ->  " .. p[2])))
	end
	texto({ Size = UDim2.new(1, -20, 0, 90), Position = UDim2.fromOffset(10, 142), Text = table.concat(partes, "\n"), TextSize = 14 }, f)
	local registros
	if b.proximamente then
		registros = "Todavía nadie lo ha cazado."
	else
		local d = datosBestiario or {}
		local mio = d.tiempos and d.tiempos[b.nombre]
		local global = d.globales and d.globales[b.nombre]
		local cazas = d.cazasPor and d.cazasPor[b.nombre] or 0
		registros = ("Cazado %d veces\nTu récord: %s\nRécord global: %s"):format(cazas, tiempo(mio), global and (tiempo(global.tiempo) .. " por " .. global.nombre) or "sin registro")
	end
	texto({ Size = UDim2.new(1, -20, 0, 80), Position = UDim2.fromOffset(10, 240), Text = "REGISTROS\n" .. registros, TextSize = 15, TextColor3 = Color3.fromRGB(255, 236, 190) }, f)
end

local function mostrarInventario()
	-- columna izquierda: el cazador en 3D y lo que lleva puesto
	local marcoVista = panel(UDim2.fromOffset(16, 72), UDim2.fromOffset(250, 290), ventana)
	vistaPersonaje(marcoVista)
	local equipo = perfil and perfil.equipo or {}
	local porRanura = {}
	for _, pieza in equipo do
		porRanura[Armas.RANURA[pieza]] = Armas.ARMADURA[pieza].nombre
	end
	local arma = perfil and Armas.DATOS[perfil.arma]
	local puesto = { "ARMA: " .. (arma and arma.nombre or "?") }
	for _, r in RANURAS do
		table.insert(puesto, string.upper(r[2]) .. ": " .. (porRanura[r[1]] or "—"))
	end
	local resumen = panel(UDim2.fromOffset(16, 370), UDim2.fromOffset(250, 146), ventana)
	texto({ Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromOffset(8, 6), Text = table.concat(puesto, "\n"), TextSize = 13, TextColor3 = Color3.fromRGB(255, 236, 190) }, resumen)
	-- columna del medio: armas y piezas para cambiar
	local izq = lista(UDim2.fromOffset(280, 72), UDim2.fromOffset(300, 444), ventana)
	local orden = 0
	local function tituloLista(t)
		orden += 1
		texto({ Size = UDim2.new(1, -10, 0, 22), Text = t, TextSize = 15, TextColor3 = DORADO, LayoutOrder = orden }, izq)
	end
	local function fila(nombre, detalle, textoBoton, activo, alPulsar)
		orden += 1
		local f = crear("Frame", { Size = UDim2.new(1, -10, 0, 48), BackgroundColor3 = activo and Color3.fromRGB(180, 146, 90) or Color3.fromRGB(150, 118, 72), BorderSizePixel = 0, LayoutOrder = orden }, izq)
		crear("UIStroke", { Thickness = 2, Color = activo and DORADO or OSCURO }, f)
		texto({ Size = UDim2.new(1, -104, 0, 20), Position = UDim2.fromOffset(8, 4), Text = nombre, TextSize = 13, TextColor3 = Color3.fromRGB(255, 230, 150) }, f)
		texto({ Size = UDim2.new(1, -104, 0, 22), Position = UDim2.fromOffset(8, 24), Text = detalle, TextSize = 10 }, f)
		boton(textoBoton, activo and DORADO or ARENA, alPulsar, f, { Position = UDim2.new(1, -94, 0.5, -14), Size = UDim2.fromOffset(88, 28), TextSize = 12 })
	end
	tituloLista("ARMAS")
	local ids = table.clone(Armas.ORDEN)
	for _, f in Armas.FAMILIAS do
		for _, id in f.armas do
			if perfil and tiene(perfil.forjadas, id) then
				table.insert(ids, id)
			end
		end
	end
	for _, id in ids do
		local d = Armas.DATOS[id]
		local elegida = perfil and perfil.arma == id
		fila(d.nombre, ("%s · daño %s"):format(d.rol, tostring(d.danio)), elegida and "Puesta" or "Elegir", elegida, function()
			Remotos.ElegirArma:FireServer(id)
		end)
	end
	for _, r in RANURAS do
		tituloLista("ARMADURA · " .. string.upper(r[2]))
		local alguna = false
		for _, pieza in Armas.TODA_ARMADURA do
			if Armas.RANURA[pieza] == r[1] and perfil and tiene(perfil.armadura, pieza) then
				alguna = true
				local puesta = tiene(perfil.equipo, pieza)
				fila(Armas.ARMADURA[pieza].nombre, Armas.ARMADURA[pieza].efecto, puesta and "Quitar" or "Poner", puesta, function()
					Remotos.AlternarPieza:FireServer(pieza)
				end)
			end
		end
		if not alguna then
			orden += 1
			texto({ Size = UDim2.new(1, -10, 0, 18), Text = "Nada forjado todavía (habla con Nefra)", TextSize = 11, LayoutOrder = orden }, izq)
		end
	end
	-- columna derecha: atributos, arma y bonos
	local der = panel(UDim2.fromOffset(594, 72), UDim2.fromOffset(210, 444), ventana)
	local lineas, sets = atributos()
	local armaTexto = arma and (("%s · daño %s"):format(arma.rol, tostring(arma.danio)) .. (Armas.FORJABLES[perfil.arma] and ("\n" .. Armas.FORJABLES[perfil.arma].poder) or "")) or ""
	texto({ Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(6, 6), Text = "ATRIBUTOS", TextSize = 15, TextColor3 = DORADO }, der)
	texto({ Size = UDim2.new(1, -12, 0, 190), Position = UDim2.fromOffset(6, 28), Text = table.concat(lineas, "\n"), TextSize = 11 }, der)
	texto({ Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(6, 220), Text = "PODER DEL ARMA", TextSize = 13, TextColor3 = DORADO }, der)
	texto({ Size = UDim2.new(1, -12, 0, 70), Position = UDim2.fromOffset(6, 240), Text = armaTexto, TextSize = 10 }, der)
	local bonos = {}
	for _, f in Armas.FAMILIAS do
		local set = f.set
		if (sets[set] or 0) >= 2 then
			table.insert(bonos, ("%s (%d/4)"):format(NOMBRE_SET[set], sets[set]))
			table.insert(bonos, "✔ " .. f.bonos[1])
			if sets[set] >= 4 then
				table.insert(bonos, "✔ " .. f.bonos[2])
			end
		end
	end
	texto({ Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(6, 312), Text = "BONOS DE SET", TextSize = 13, TextColor3 = DORADO }, der)
	texto({ Size = UDim2.new(1, -12, 1, -336), Position = UDim2.fromOffset(6, 332), Text = #bonos > 0 and table.concat(bonos, "\n") or "Ponte 2 piezas del mismo set para activar su bono.", TextSize = 10 }, der)
end

function Menu.mostrar()
	if not abierto then
		return
	end
	limpiar()
	if pestana == "inventario" and not enRefugio() then
		pestana = "bestiario" -- el inventario solo se abre en el Refugio
	end
	cabecera()
	if pestana == "bestiario" then
		mostrarBestiario()
	else
		mostrarInventario()
	end
	boton("Cerrar (B)", Color3.fromRGB(200, 120, 90), Menu.cerrar, ventana, { Position = UDim2.new(1, -166, 1, -44) })
	if primerBoton and GuiService.SelectedObject == nil then
		GuiService.SelectedObject = primerBoton
	end
end

function Menu.abrir()
	if abierto then
		return
	end
	abierto = true
	ventana.Visible = true
	if alCambiar then
		alCambiar(true)
	end
	Menu.mostrar()
	task.spawn(function()
		local ok, d = pcall(function()
			return Remotos.PedirBestiario:InvokeServer()
		end)
		if ok and d then
			datosBestiario = d
			if perfil then
				perfil.nivel, perfil.xp = d.nivel, d.xp
			end
			GuiService.SelectedObject = nil
			Menu.mostrar()
		end
	end)
end

function Menu.cerrar()
	if not abierto then
		return
	end
	abierto = false
	ventana.Visible = false
	GuiService.SelectedObject = nil
	if alCambiar then
		alCambiar(false)
	end
end

function Menu.alternar()
	if abierto then
		Menu.cerrar()
	elseif jugador:GetAttribute("Zona") ~= "probador" then
		Menu.abrir()
	end
end

function Menu.iniciar(callback)
	alCambiar = callback
	gui = crear("ScreenGui", { Name = "MenuCazador", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5 }, jugador:WaitForChild("PlayerGui"))
	ventana = crear("Frame", { Size = UDim2.fromOffset(820, 560), Position = UDim2.new(0.5, -410, 0.5, -280), BackgroundColor3 = ARENA, BorderSizePixel = 0, Visible = false }, gui)
	crear("UIStroke", { Thickness = 4, Color = OSCURO }, ventana)
	Escala.ajustar(ventana, 820, 560)
	Remotos.Perfil.OnClientEvent:Connect(function(p)
		perfil = p
		if abierto then
			Menu.mostrar()
			task.delay(0.4, function()
				if abierto and pestana == "inventario" then
					Menu.mostrar()
				end
			end)
		end
	end)
	ContextActionService:BindActionAtPriority("AbrirMenu", function(_, estadoInput)
		if estadoInput == Enum.UserInputState.Begin then
			if abierto then
				Menu.cerrar()
			elseif jugador:GetAttribute("Zona") ~= "probador" then
				Menu.abrir()
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.M, Enum.KeyCode.ButtonSelect)
end

return Menu
