--!nonstrict
-- Estados que los poderes de las armas dejan en los Behemoths: veneno, quemadura, sangrado y lentitud.
-- Sirve para Sekhmaur y para Kheprak.
local Estados = {}

function Estados.iniciar(b)
	b.veneno, b.venenoDps = 0, 0
	b.quemadura, b.quemaduraDps = 0, 0
	b.lentitud = 0
	b.sangrado, b.sangradoDps = 0, 0
	b.tNumeroEstado = 0
end

-- lo que trae un golpe: info.veneno / info.quemadura (daño por segundo) e info.lentitud (segundos)
function Estados.aplicar(b, info)
	-- si el estado ya terminó, el nuevo empieza con su propio daño (no con el más alto de antes)
	if (info.veneno or 0) > 0 then
		b.venenoDps = math.max(b.veneno > 0 and b.venenoDps or 0, info.veneno)
		b.veneno = 6
	end
	if (info.quemadura or 0) > 0 then
		b.quemaduraDps = math.max(b.quemadura > 0 and b.quemaduraDps or 0, info.quemadura)
		b.quemadura = 5
	end
	if (info.lentitud or 0) > 0 then
		b.lentitud = math.max(b.lentitud, info.lentitud)
	end
	if (info.sangrado or 0) > 0 then
		b.sangradoDps = math.max((b.sangrado or 0) > 0 and (b.sangradoDps or 0) or 0, info.sangrado)
		b.sangrado = 5
	end
end

function Estados.paso(b, dt: number)
	if b.muerto then
		if b.veneno > 0 or b.quemadura > 0 or b.lentitud > 0 or (b.sangrado or 0) > 0 then
			b.veneno, b.quemadura, b.lentitud, b.sangrado = 0, 0, 0, 0
			b.modelo:SetAttribute("Sangrando", false)
			b.modelo:SetAttribute("Envenenado", false)
			b.modelo:SetAttribute("Quemado", false)
			b.modelo:SetAttribute("Lento", false)
		end
		return
	end
	b.sangrado = b.sangrado or 0
	b.lentitud = math.max(0, b.lentitud - dt)
	b.tNumeroEstado -= dt
	local mostrar = b.tNumeroEstado <= 0
	if mostrar then
		b.tNumeroEstado = 1
	end
	local pos = b.raiz.Position + Vector3.new(0, 20, 0)
	if b.veneno > 0 then
		b.veneno -= dt
		b:_danio(b.venenoDps * dt)
		if mostrar then
			b.servicios.numero(pos, tostring(math.floor(b.venenoDps + 0.5)), Color3.fromRGB(210, 130, 255)) -- veneno en morado
		end
	end
	if b.quemadura > 0 then
		b.quemadura -= dt
		b:_danio(b.quemaduraDps * dt)
		if mostrar then
			b.servicios.numero(pos + Vector3.new(3, 0, 0), tostring(math.floor(b.quemaduraDps + 0.5)), Color3.fromRGB(255, 154, 46))
		end
	end
	if b.sangrado > 0 then
		b.sangrado -= dt
		b:_danio(b.sangradoDps * dt)
		if mostrar then
			b.servicios.numero(pos + Vector3.new(-3, 0, 0), tostring(math.floor(b.sangradoDps + 0.5)), Color3.fromRGB(230, 40, 50))
		end
	end
	b.modelo:SetAttribute("Sangrando", b.sangrado > 0)
	b.modelo:SetAttribute("Envenenado", b.veneno > 0)
	b.modelo:SetAttribute("Quemado", b.quemadura > 0)
	b.modelo:SetAttribute("Lento", b.lentitud > 0)
end

-- multiplicador de velocidad (las arenas movedizas lo frenan)
function Estados.freno(b): number
	return b.lentitud > 0 and 0.5 or 1
end

return Estados
