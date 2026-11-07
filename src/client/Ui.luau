-- Small helpers for building the screens in code: one look everywhere, phone-sized targets.
local Ui = {}

Ui.INK = Color3.fromHex("1f2329")
Ui.PANEL = Color3.fromHex("fffaf0")
Ui.ACCENT = Color3.fromHex("ff7a45")
Ui.GOOD = Color3.fromHex("2f9e6e")
Ui.MUTED = Color3.fromHex("6a6f78")

function Ui.make(className: string, props: { [string]: any }, children: { Instance }?): any
	local object = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(object :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = object
	end
	object.Parent = props.Parent
	return object
end

function Ui.corner(radius: number?): UICorner
	return Ui.make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Ui.pad(px: number): UIPadding
	local p = UDim.new(0, px)
	return Ui.make("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

function Ui.label(text: string, size: number, color: Color3?, props: { [string]: any }?): TextLabel
	local base = {
		Text = text,
		TextSize = size,
		TextColor3 = color or Ui.INK,
		Font = Enum.Font.GothamBold,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in props or {} do
		base[k] = v
	end
	return Ui.make("TextLabel", base)
end

function Ui.stars(n: number): string
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

function Ui.clock(seconds: number): string
	return `{math.max(0, math.ceil(seconds))}s`
end

return Ui
