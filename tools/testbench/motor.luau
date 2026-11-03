--!nocheck
-- Motor falso de Roblox para probar los módulos del juego con Lune, sin Studio.
-- Instancias en Luau puro (con Position ligada a CFrame), reloj simulado y planificador de tareas.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Motor = {}

local Vector3 = roblox.Vector3
-- CFrame de Lune con lookAt corregido (Lune se equivoca cuando se mira justo hacia +Z)
local CFrame = setmetatable({}, { __index = roblox.CFrame })
function CFrame.lookAt(desde, hacia, arriba)
	arriba = arriba or Vector3.new(0, 1, 0)
	local atras = desde - hacia
	if atras.Magnitude < 1e-6 then
		return roblox.CFrame.new(desde)
	end
	atras = atras.Unit
	local x = arriba:Cross(atras)
	if x.Magnitude < 1e-6 then
		x = Vector3.new(1, 0, 0)
	end
	x = x.Unit
	local y = atras:Cross(x)
	return roblox.CFrame.fromMatrix(desde, x, y, atras)
end
Motor.CFrame = CFrame

-- ---------- reloj y tareas ----------
local reloj = { t = 1000 }
local cola = {}
local errores = {}
Motor.errores = errores
Motor.reloj = reloj

local function reanudar(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		local msg = tostring(err) .. "\n" .. debug.traceback(co)
		table.insert(errores, msg)
		print("ERROR en tarea: " .. msg)
	end
end

local task = {}
function task.spawn(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	reanudar(co, ...)
	return co
end
function task.defer(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	table.insert(cola, { t = reloj.t, co = co, args = table.pack(...) })
	return co
end
function task.delay(s, f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	table.insert(cola, { t = reloj.t + (s or 0), co = co, args = table.pack(...) })
	return co
end
function task.wait(s)
	local co = coroutine.running()
	local t0 = reloj.t
	table.insert(cola, { t = reloj.t + math.max(s or 0, 1 / 60), co = co, espera = t0 })
	return coroutine.yield()
end
function task.cancel(co)
	for _, x in cola do
		if x.co == co then
			x.cancelada = true
		end
	end
end
Motor.task = task

-- avanza el reloj y ejecuta las tareas que tocan
function Motor.avanzar(dt)
	reloj.t += dt
	local hubo = true
	while hubo do
		hubo = false
		for i, x in cola do
			if x.t <= reloj.t then
				table.remove(cola, i)
				hubo = true
				if not x.cancelada and coroutine.status(x.co) == "suspended" then
					if x.espera then
						reanudar(x.co, reloj.t - x.espera)
					else
						reanudar(x.co, table.unpack(x.args, 1, x.args.n))
					end
				end
				break
			end
		end
	end
end

-- ---------- señales ----------
local function nuevaSenal()
	local s = { _f = {} }
	function s:Connect(f)
		local c = { Connected = true }
		table.insert(s._f, c)
		c.f = f
		function c:Disconnect()
			c.Connected = false
		end
		return c
	end
	function s:Once(f)
		local c
		c = s:Connect(function(...)
			c:Disconnect()
			f(...)
		end)
		return c
	end
	function s:Wait()
		local co = coroutine.running()
		s:Once(function(...)
			task.spawn(co, ...)
		end)
		return coroutine.yield()
	end
	function s:Fire(...)
		for _, c in table.clone(s._f) do
			if c.Connected then
				task.spawn(c.f, ...)
			end
		end
	end
	return s
end
Motor.nuevaSenal = nuevaSenal

-- ---------- instancias ----------
local HERENCIA = {
	Part = { "BasePart", "PVInstance" }, WedgePart = { "BasePart", "PVInstance" }, MeshPart = { "BasePart", "PVInstance" },
	TrussPart = { "BasePart", "PVInstance" }, SpawnLocation = { "Part", "BasePart", "PVInstance" },
	Model = { "PVInstance" }, Workspace = { "Model", "PVInstance" },
	Motor6D = { "JointInstance" }, Weld = { "JointInstance" }, WeldConstraint = { "Constraint" },
	PointLight = { "Light" }, SpotLight = { "Light" }, SurfaceLight = { "Light" },
	ModuleScript = { "LuaSourceContainer" }, Script = { "BaseScript", "LuaSourceContainer" }, LocalScript = { "BaseScript", "LuaSourceContainer" },
	TextLabel = { "GuiObject", "GuiBase2d" }, Frame = { "GuiObject", "GuiBase2d" }, TextButton = { "GuiButton", "GuiObject", "GuiBase2d" },
	ImageLabel = { "GuiObject", "GuiBase2d" }, BillboardGui = { "LayerCollector", "GuiBase2d" }, ScreenGui = { "LayerCollector", "GuiBase2d" },
	SurfaceGui = { "LayerCollector", "GuiBase2d" },
}

local DEFECTO = {
	BasePart = function()
		return {
			Size = Vector3.new(4, 1, 2), CFrame = CFrame.new(), Transparency = 0, Color = roblox.Color3.fromRGB(163, 162, 165),
			Anchored = false, CanCollide = true, CanQuery = true, CanTouch = true, Massless = false, CastShadow = true,
			Material = roblox.Enum.Material.Plastic, Shape = roblox.Enum.PartType.Block, Reflectance = 0,
			TopSurface = roblox.Enum.SurfaceType.Smooth, BottomSurface = roblox.Enum.SurfaceType.Smooth, Locked = false,
			AssemblyLinearVelocity = Vector3.zero,
		}
	end,
	Model = function()
		return { PrimaryPart = nil, ModelStreamingMode = roblox.Enum.ModelStreamingMode.Default, WorldPivot = CFrame.new() }
	end,
	JointInstance = function()
		return { C0 = CFrame.new(), C1 = CFrame.new(), Part0 = nil, Part1 = nil, Enabled = true, Transform = CFrame.new() }
	end,
	Humanoid = function()
		return { Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2, HipHeight = 0, RootPart = nil, Sit = false, PlatformStand = false, AutoRotate = true }
	end,
	ParticleEmitter = function()
		return { Rate = 5, Enabled = true, Lifetime = roblox.NumberRange.new(5, 10), Speed = roblox.NumberRange.new(5), LightEmission = 0, LockedToPart = false }
	end,
	Attachment = function()
		return { CFrame = CFrame.new(), Position = Vector3.zero }
	end,
	Player = function()
		return { Character = nil, UserId = 1, DisplayName = "Jugador" }
	end,
	Light = function()
		return { Brightness = 1, Range = 8, Color = roblox.Color3.new(1, 1, 1), Enabled = true, Shadows = false }
	end,
}

local Inst = {}
local metodos = {}
local MT = {}

local function clasesDe(clase)
	local l = { clase }
	for _, c in HERENCIA[clase] or {} do
		table.insert(l, c)
	end
	table.insert(l, "Instance")
	return l
end

local SENALES = {
	Heartbeat = true, PreSimulation = true, PostSimulation = true, RenderStepped = true, Stepped = true, PreRender = true,
	PlayerAdded = true, PlayerRemoving = true, CharacterAdded = true, CharacterRemoving = true,
	OnServerEvent = true, OnClientEvent = true, Touched = true, TouchEnded = true, ChildAdded = true, ChildRemoved = true,
	DescendantAdded = true, DescendantRemoving = true, Died = true, AncestryChanged = true, Triggered = true,
	Changed = true, Destroying = true, MouseButton1Click = true, Activated = true, PromptTriggered = true, HealthChanged = true,
}

function Inst.new(clase, padre)
	local d = { _clase = clase, _hijos = {}, _attrs = {}, _p = { Name = clase, Parent = nil }, _senales = {}, _clases = clasesDe(clase) }
	for _, c in d._clases do
		if DEFECTO[c] then
			for k, v in DEFECTO[c]() do
				d._p[k] = v
			end
		end
	end
	local o = setmetatable(d, MT)
	if padre then
		o.Parent = padre
	end
	return o
end
Motor.Instance = Inst

MT.__index = function(o, k)
	if k == "ClassName" then
		return rawget(o, "_clase")
	end
	local p = rawget(o, "_p")
	if k == "Position" and p.CFrame then
		return p.CFrame.Position
	end
	if k == "Orientation" and p.CFrame then
		local x, y, z = p.CFrame:ToOrientation()
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	end
	if k == "Rotation" and p.CFrame then
		return Vector3.zero
	end
	local v = p[k]
	if v ~= nil then
		return v
	end
	if metodos[k] then
		return metodos[k]
	end
	if SENALES[k] then
		local s = o._senales[k]
		if not s then
			s = nuevaSenal()
			o._senales[k] = s
		end
		return s
	end
	-- un hijo con ese nombre
	for _, h in rawget(o, "_hijos") do
		if h.Name == k then
			return h
		end
	end
	if p[k] == nil and (k == "Parent" or k == "PrimaryPart" or k == "Part0" or k == "Part1" or k == "Character" or k == "RootPart" or k == "Adornee" or k == "Attachment0" or k == "Attachment1" or k == "SoundId" or k == "Image" or k == "Text") then
		return nil
	end
	-- propiedades que no nos importan: se aceptan con valor nulo para no romper el código
	if string.match(k, "^%u") and not rawget(o, "_estricto") then
		return nil
	end
	error(tostring(k) .. " is not a valid member of " .. rawget(o, "_clase"), 2)
end

local function quitarDe(padre, o)
	if padre then
		local hs = rawget(padre, "_hijos")
		for i, h in hs do
			if h == o then
				table.remove(hs, i)
				break
			end
		end
	end
end

MT.__newindex = function(o, k, v)
	local p = rawget(o, "_p")
	if k == "Parent" then
		if v == o then
			error("no puede ser su propio padre")
		end
		local viejo = p.Parent
		if viejo == v then
			return
		end
		quitarDe(viejo, o)
		p.Parent = v
		if v then
			table.insert(rawget(v, "_hijos"), o)
			-- avisar a los ancestros
			local a = v
			while a do
				local s = rawget(a, "_senales").DescendantAdded
				if s then
					s:Fire(o)
				end
				a = rawget(a, "_p").Parent
			end
			local s = rawget(v, "_senales").ChildAdded
			if s then
				s:Fire(o)
			end
		end
		return
	end
	if k == "Position" and p.CFrame then
		p.CFrame = p.CFrame.Rotation + v
		return
	end
	if k == "Orientation" and p.CFrame then
		p.CFrame = CFrame.new(p.CFrame.Position) * CFrame.fromOrientation(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
		return
	end
	p[k] = v
end

MT.__tostring = function(o)
	return rawget(o, "_p").Name
end

function metodos:IsA(c)
	for _, x in rawget(self, "_clases") do
		if x == c then
			return true
		end
	end
	return false
end
function metodos:GetChildren()
	return table.clone(rawget(self, "_hijos"))
end
function metodos:GetDescendants()
	local l = {}
	local function rec(o)
		for _, h in rawget(o, "_hijos") do
			table.insert(l, h)
			rec(h)
		end
	end
	rec(self)
	return l
end
function metodos:FindFirstChild(n, recursivo)
	for _, h in rawget(self, "_hijos") do
		if h.Name == n then
			return h
		end
	end
	if recursivo then
		for _, h in rawget(self, "_hijos") do
			local r = h:FindFirstChild(n, true)
			if r then
				return r
			end
		end
	end
	return nil
end
function metodos:WaitForChild(n)
	local r = self:FindFirstChild(n)
	if not r then
		error("WaitForChild nunca encontraría " .. tostring(n) .. " en " .. self.Name)
	end
	return r
end
function metodos:FindFirstChildOfClass(c)
	for _, h in rawget(self, "_hijos") do
		if h.ClassName == c then
			return h
		end
	end
	return nil
end
function metodos:FindFirstChildWhichIsA(c, recursivo)
	for _, h in (recursivo and self:GetDescendants() or rawget(self, "_hijos")) do
		if h:IsA(c) then
			return h
		end
	end
	return nil
end
function metodos:FindFirstAncestor(n)
	local a = self.Parent
	while a do
		if a.Name == n then
			return a
		end
		a = a.Parent
	end
	return nil
end
function metodos:FindFirstAncestorWhichIsA(c)
	local a = self.Parent
	while a do
		if a:IsA(c) then
			return a
		end
		a = a.Parent
	end
	return nil
end
function metodos:FindFirstAncestorOfClass(c)
	local a = self.Parent
	while a do
		if a.ClassName == c then
			return a
		end
		a = a.Parent
	end
	return nil
end
function metodos:IsDescendantOf(x)
	local a = self.Parent
	while a do
		if a == x then
			return true
		end
		a = a.Parent
	end
	return false
end
function metodos:Destroy()
	for _, h in self:GetChildren() do
		h:Destroy()
	end
	self.Parent = nil
	rawset(self, "_destruido", true)
end
function metodos:ClearAllChildren()
	for _, h in self:GetChildren() do
		h:Destroy()
	end
end
function metodos:Clone()
	local c = Inst.new(self.ClassName)
	for k, v in rawget(self, "_p") do
		if k ~= "Parent" then
			rawget(c, "_p")[k] = v
		end
	end
	for k, v in rawget(self, "_attrs") do
		rawget(c, "_attrs")[k] = v
	end
	for _, h in rawget(self, "_hijos") do
		h:Clone().Parent = c
	end
	return c
end
function metodos:SetAttribute(k, v)
	local a = rawget(self, "_attrs")
	if a[k] ~= v then
		a[k] = v
		local s = rawget(self, "_senales")["Attr_" .. k]
		if s then
			s:Fire()
		end
	end
end
function metodos:GetAttribute(k)
	return rawget(self, "_attrs")[k]
end
function metodos:GetAttributes()
	return table.clone(rawget(self, "_attrs"))
end
function metodos:GetAttributeChangedSignal(k)
	local ss = rawget(self, "_senales")
	ss["Attr_" .. k] = ss["Attr_" .. k] or nuevaSenal()
	return ss["Attr_" .. k]
end
function metodos:GetPropertyChangedSignal(k)
	local ss = rawget(self, "_senales")
	ss["Prop_" .. k] = ss["Prop_" .. k] or nuevaSenal()
	return ss["Prop_" .. k]
end
function metodos:GetFullName()
	local n = self.Name
	local a = self.Parent
	while a and a.ClassName ~= "DataModel" do
		n = a.Name .. "." .. n
		a = a.Parent
	end
	return n
end
-- servicios
function metodos:GetService(n)
	local s = self:FindFirstChild(n)
	if not s then
		s = Inst.new(n)
		s.Name = n
		s.Parent = self
	end
	return s
end
function metodos:IsServer()
	return Motor.esServidor
end
function metodos:IsClient()
	return not Motor.esServidor
end
function metodos:IsStudio()
	return false
end
function metodos:GetServerTimeNow()
	return reloj.t
end
function metodos:GetPlayers()
	return self:GetChildren()
end
function metodos:AddItem(o, s)
	task.delay(s or 10, function()
		if o.Parent then
			o:Destroy()
		end
	end)
end
-- remotos: se guardan en un registro para poder revisarlos
Motor.remotos = {}
function metodos:FireClient(j, ...)
	table.insert(Motor.remotos, { self.Name, j, ... })
end
function metodos:FireAllClients(...)
	table.insert(Motor.remotos, { self.Name, "todos", ... })
end
function metodos:FireServer(...) end
function metodos:Emit(n) end
function metodos:Play() end
function metodos:Stop() end
function metodos:TakeDamage(d)
	self.Health = math.max(0, self.Health - d)
end
function metodos:GetPivot()
	if self.ClassName == "Model" or self.ClassName == "Workspace" then
		return self.PrimaryPart and self.PrimaryPart.CFrame or CFrame.new()
	end
	return self.CFrame
end
function metodos:PivotTo(cf)
	if self.CFrame then
		self.CFrame = cf
	elseif self.PrimaryPart then
		self.PrimaryPart.CFrame = cf
	end
end
function metodos:SetPrimaryPartCFrame(cf)
	self:PivotTo(cf)
end
function metodos:GetMass()
	return 1
end
function metodos:SetNetworkOwner() end
function metodos:BreakJoints() end
function metodos:MoveTo(p) end
function metodos:LoadCharacter() end
function metodos:Kick() end
function metodos:GetPartBoundsInRadius()
	return {}
end
function metodos:GetPartBoundsInBox()
	return {}
end
function metodos:Raycast()
	return nil
end
function metodos:FillBlock() end
function metodos:FillBall() end
function metodos:FillCylinder() end
function metodos:FillWedge() end
function metodos:Clear() end
function metodos:Create(o, info, props)
	-- TweenService: aplica el final directamente
	return {
		Play = function()
			for k, v in props do
				o[k] = v
			end
		end,
		Cancel = function() end,
		Completed = nuevaSenal(),
	}
end

-- ---------- entorno de los módulos ----------
local Random = {}
Random.__index = Random
function Random.new()
	return setmetatable({}, Random)
end
function Random:NextNumber(a, b)
	a, b = a or 0, b or 1
	return a + math.random() * (b - a)
end
function Random:NextInteger(a, b)
	return math.random(a, b)
end

local function tipoDe(x)
	if type(x) == "table" and rawget(x, "_clase") then
		return "Instance"
	end
	return typeof(x)
end

local osFalso = setmetatable({
	clock = function()
		return reloj.t
	end,
}, { __index = os })

function Motor.crearJuego()
	local juego = Inst.new("DataModel")
	juego.Name = "Juego"
	local ws = juego:GetService("Workspace")
	Motor.juego = juego
	Motor.workspace = ws
	return juego
end

-- módulos: instancia -> ruta del archivo
local rutas = {}
local cache = {}
function Motor.modulo(padre, nombre, ruta)
	local m = Inst.new("ModuleScript")
	m.Name = nombre
	m.Parent = padre
	rutas[m] = ruta
	return m
end

function Motor.carpeta(padre, nombre, dir)
	local f = Inst.new("Folder")
	f.Name = nombre
	f.Parent = padre
	for _, archivo in fs.readDir(dir) do
		local n = string.match(archivo, "^(.-)%.luau$")
		if n and not string.find(n, "%.") then
			Motor.modulo(f, n, dir .. "/" .. archivo)
		end
	end
	return f
end

local function entorno(script)
	local env = {}
	env.script = script
	env.game = Motor.juego
	env.workspace = Motor.workspace
	env.Instance = Inst
	env.task = task
	env.os = osFalso
	env.tick = function()
		return reloj.t
	end
	env.time = env.tick
	env.typeof = tipoDe
	env.Random = Random
	env.warn = function(...)
		print("AVISO:", ...)
	end
	env.require = Motor.require
	env.CFrame = CFrame
	for _, k in { "Vector3", "Vector2", "Color3", "Enum", "UDim", "UDim2", "NumberSequence", "NumberSequenceKeypoint",
		"ColorSequence", "ColorSequenceKeypoint", "NumberRange", "Rect", "Ray", "BrickColor", "Font", "PhysicalProperties",
		"Region3", "Axes", "Faces", "TweenInfo", "RaycastParams", "OverlapParams", "DateTime", "Vector3int16" } do
		env[k] = roblox[k]
	end
	for _, k in { "math", "table", "string", "coroutine", "utf8", "bit32", "buffer", "debug", "print", "error", "pcall", "xpcall",
		"type", "tostring", "tonumber", "ipairs", "pairs", "next", "select", "setmetatable", "getmetatable", "rawget", "rawset",
		"rawequal", "rawlen", "unpack", "assert", "newproxy", "gcinfo" } do
		env[k] = _G[k] or getfenv()[k]
	end
	env.table = table
	env.string = string
	env.math = math
	env.unpack = table.unpack
	env._G = env
	env.shared = {}
	return env
end

function Motor.require(m)
	if type(m) == "string" then
		error("require por texto no soportado: " .. m)
	end
	if cache[m] ~= nil then
		return cache[m]
	end
	local ruta = rutas[m]
	if not ruta then
		error("módulo sin archivo: " .. m:GetFullName())
	end
	local f = luau.load(fs.readFile(ruta), { debugName = ruta, environment = entorno(m) })
	local r = f()
	cache[m] = r
	return r
end

-- carga un archivo suelto con el entorno falso (por ejemplo, un script del cliente)
function Motor.cargarComo(script, ruta)
	rutas[script] = ruta
	return Motor.require(script)
end

return Motor
