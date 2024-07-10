
local xcloneref = function(v) return v end
local xclonefunction = function(v) return v end

-- // Variables
local TextService = xcloneref(game:GetService("TextService"))
local HttpService = xcloneref(game:GetService("HttpService"))

local HttpGet = xclonefunction(_httpget)
local GetTextBoundsAsync = xclonefunction(TextService.GetTextBoundsAsync)

-- // Drawing
local Drawing = {}

Drawing.__CLASSES = {}
Drawing.__OBJECT_CACHE = {}
Drawing.__IMAGE_CACHE = {}

Drawing.Font = {
    Count = 0,
    Fonts = {},
    Enums = {}
}

function Drawing.new(class)
    if not Drawing.__CLASSES[class] then
        error(`Invalid argument #1, expected a valid drawing type`, 2)
    end

    return Drawing.__CLASSES[class].new()
end

function Drawing.Font.new(FontName, FontData)

    local FontID = Drawing.Font.Count
    local FontObject

    Drawing.Font.Count += 1
    Drawing.Font.Fonts[FontName] = FontID

    if string.sub(FontData, 1, 11) == "rbxasset://" then
        FontObject = Font.new(FontData, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    else
        local TempPath = HttpService:GenerateGUID(false)

        if not isfile(FontData) then
            writefile(`DrawingFontCache/{FontName}.ttf`, crypt.base64.decode(FontData))
            FontData = `DrawingFontCache/{FontName}.ttf`
        end
    
        writefile(TempPath, HttpService:JSONEncode({
            ["name"] = FontName,
            ["faces"] = {
                {
                    ["name"] = "Regular",
                    ["weight"] = 100,
                    ["style"] = "normal",
                    ["assetId"] = getcustomasset(FontData)
                }
            }
        }))

        FontObject = Font.new(getcustomasset(TempPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)

        delfile(TempPath)
    end

    if not FontObject then
        error("Internal Error while creating new font.", 2)
    end

    Drawing.__TEXT_BOUND_PARAMS.Text = "Text"
    Drawing.__TEXT_BOUND_PARAMS.Size = 12
    Drawing.__TEXT_BOUND_PARAMS.Font = FontObject
    Drawing.__TEXT_BOUND_PARAMS.Width = math.huge

    GetTextBoundsAsync(TextService, Drawing.__TEXT_BOUND_PARAMS) -- Preload/Cache font for GetTextBoundsAsync to avoid yielding across metamethods

    Drawing.Font.Enums[FontID] = FontObject

    return FontObject
end

function Drawing.CreateInstance(class, properties, children)
    local object = Instance.new(class)

    for property, value in properties or {} do
        object[property] = value
    end

    for idx, child in children or {} do
        child.Parent = object
    end

    return object
end

function Drawing.ClearCache()
    for idx, object in Drawing.__OBJECT_CACHE do
        if rawget(object, "__OBJECT_EXISTS") then
            object:Remove()
        end
    end
end

function Drawing.UpdatePosition(object, from, to, thickness)
    local center = (from + to) / 2
    local offset = to - from

    object.Position = UDim2.fromOffset(center.X, center.Y)
    object.Size = UDim2.fromOffset(offset.Magnitude, thickness)
    object.Rotation = math.atan2(offset.Y, offset.X) * 180 / math.pi
end

Drawing.__ROOT = Drawing.CreateInstance("ScreenGui", {
    IgnoreGuiInset = true,
    DisplayOrder = 10,
    Name = HttpService:GenerateGUID(false),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = gethui()
})

Drawing.__TEXT_BOUND_PARAMS = Drawing.CreateInstance("GetTextBoundsParams", { Width = math.huge })

--#region Line
local Line = {}

Drawing.__CLASSES["Line"] = Line

function Line.new()
    local LineObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            From = Vector2.zero,
            To = Vector2.zero,
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        })
    }, Line)

    table.insert(Drawing.__OBJECT_CACHE, LineObject)

    return LineObject
end

function Line:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Line[property]
end

function Line:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.BackgroundColor3 = value
    elseif property == "From" then
        Drawing.UpdatePosition(self.__OBJECT, Properties.From, Properties.To, Properties.Thickness)
    elseif property == "To" then
        Drawing.UpdatePosition(self.__OBJECT, Properties.From, Properties.To, Properties.Thickness)
    elseif property == "Thickness" then
        self.__OBJECT.Size = UDim2.fromOffset(self.__OBJECT.AbsoluteSize.X, math.max(value, 1))
    elseif property == "Transparency" then
        self.__OBJECT.Transparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Line:__iter()
    return next, self.__PROPERTIES
end

function Line:__tostring()
    return "Drawing"
end

function Line:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Line:Destroy()
    self:Remove()
end
--#endregion

--#region Circle
local Circle = {}

Drawing.__CLASSES["Circle"] = Circle

function Circle.new()
    local CircleObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            NumSides = 0,
            Radius = 0,
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UICorner", {
                Name = "_CORNER",
                CornerRadius = UDim.new(1, 0)
            }),
            Drawing.CreateInstance("UIStroke", {
                Name = "_STROKE",
                Color = Color3.new(0, 0, 0),
                Thickness = 1
            })
        }),
    }, Circle)

    table.insert(Drawing.__OBJECT_CACHE, CircleObject)

    return CircleObject
end

function Circle:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Circle[property]
end

function Circle:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.BackgroundColor3 = value
        self.__OBJECT._STROKE.Color = value
    elseif property == "Filled" then
        self.__OBJECT.BackgroundTransparency = value and 1 - Properties.Transparency or 1
    elseif property == "Position" then
        self.__OBJECT.Position = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Radius" then
        self:__UPDATE_RADIUS()
    elseif property == "Thickness" then
        self:__UPDATE_RADIUS()
    elseif property == "Transparency" then
        self.__OBJECT._STROKE.Transparency = math.clamp(1 - value, 0, 1)
        self.__OBJECT.Transparency = Properties.Filled and math.clamp(1 - value, 0, 1) or self.__OBJECT.Transparency
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Circle:__iter()
    return next, self.__PROPERTIES
end

function Circle:__tostring()
    return "Drawing"
end

function Circle:__UPDATE_RADIUS()
    local diameter = (self.__PROPERTIES.Radius * 2) - (self.__PROPERTIES.Thickness * 2)
    self.__OBJECT.Size = UDim2.fromOffset(diameter, diameter)
end

function Circle:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Circle:Destroy()
    self:Remove()
end
--#endregion

--#region Text
local Text = {}

Drawing.__CLASSES["Text"] = Text

function Text.new()
    local TextObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(1, 1, 1),
            OutlineColor = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            TextBounds = Vector2.new(0, 0),
            Text = "",
            Font = Drawing.Font.Enums[2],
            Size = 13,
            Transparency = 1,
            ZIndex = 0,
            Center = false,
            Outline = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("TextLabel", {
            TextColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            FontFace = Drawing.Font.Enums[1],
            TextSize = 12,
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UIStroke", {
                Name = "_STROKE",
                Color = Color3.new(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Enabled = false,
                Thickness = 1
            })
        })
    }, Text)

    table.insert(Drawing.__OBJECT_CACHE, TextObject)

    return TextObject
end

function Text:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Text[property]
end

function Text:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    if value == "TextBounds" then
        error("Attempt to modify read-only property", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.TextColor3 = value
    elseif property == "Position" then
        self.__OBJECT.Position = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Size" then
        self.__OBJECT.TextSize = value - 1
        self:_UPDATE_TEXT_BOUNDS()
    elseif property == "Text" then
        self.__OBJECT.Text = value
        self:_UPDATE_TEXT_BOUNDS()
    elseif property == "Font" then
        if type(value) == "string" then
            value = Drawing.Font.Enums[Drawing.Font.Fonts[value]]
        elseif type(value) == "number" then
            value = Drawing.Font.Enums[value]
        end

        Properties.Font = value

        self.__OBJECT.FontFace = value
        self:_UPDATE_TEXT_BOUNDS()
    elseif property == "Outline" then
        self.__OBJECT._STROKE.Enabled = value
    elseif property == "OutlineColor" then
        self.__OBJECT._STROKE.Color = value
    elseif property == "Center" then
        self.__OBJECT.TextXAlignment = value and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    elseif property == "Transparency" then
        self.__OBJECT.Transparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Text:__iter()
    return next, self.__PROPERTIES
end

function Text:__tostring()
    return "Drawing"
end

function Text:_UPDATE_TEXT_BOUNDS()
    local Properties = self.__PROPERTIES

    Drawing.__TEXT_BOUND_PARAMS.Text = Properties.Text
    Drawing.__TEXT_BOUND_PARAMS.Size = Properties.Size - 1
    Drawing.__TEXT_BOUND_PARAMS.Font = Properties.Font
    Drawing.__TEXT_BOUND_PARAMS.Width = math.huge

    Properties.TextBounds = GetTextBoundsAsync(TextService, Drawing.__TEXT_BOUND_PARAMS)
end

function Text:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Text:Destroy()
    self:Remove()
end
--#endregion

--#region Square
local Square = {}

Drawing.__CLASSES["Square"] = Square

function Square.new()
    local SquareObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            Size = Vector2.new(0, 0),
            Rounding = 0,
            Thickness = 0,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UIStroke", {
                Name = "_STROKE",
                Color = Color3.new(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Thickness = 1
            }),
            Drawing.CreateInstance("UICorner", {
                Name = "_CORNER",
                CornerRadius = UDim.new(0, 0)
            })
        })
    }, Square)

    table.insert(Drawing.__OBJECT_CACHE, SquareObject)

    return SquareObject
end

function Square:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Square[property]
end

function Square:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.BackgroundColor3 = value
        self.__OBJECT._STROKE.Color = value
    elseif property == "Position" then
        self:__UPDATE_SCALE()
    elseif property == "Size" then
        self:__UPDATE_SCALE()
    elseif property == "Thickness" then
        self.__OBJECT._STROKE.Thickness = value
        self.__OBJECT._STROKE.Enabled = not Properties.Filled
        self:__UPDATE_SCALE()
    elseif property == "Rounding" then
        self.__OBJECT._CORNER.CornerRadius = UDim.new(0, value)
    elseif property == "Filled" then
        self.__OBJECT._STROKE.Enabled = not value
        self.__OBJECT.BackgroundTransparency = value and 1 - Properties.Transparency or 1
    elseif property == "Transparency" then
        self.__OBJECT.Transparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Square:__iter()
    return next, self.__PROPERTIES
end

function Square:__tostring()
    return "Drawing"
end

function Square:__UPDATE_SCALE()
    local Properties = self.__PROPERTIES

    self.__OBJECT.Position = UDim2.fromOffset(Properties.Position.X + Properties.Thickness, Properties.Position.Y + Properties.Thickness)
    self.__OBJECT.Size = UDim2.fromOffset(Properties.Size.X - Properties.Thickness * 2, Properties.Size.Y - Properties.Thickness * 2)
end

function Square:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Square:Destroy()
    self:Remove()
end
--#endregion


--#region Image
local Image = {}

Drawing.__CLASSES["Image"] = Image

function Image.new()
    local ImageObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            Size = Vector2.new(0, 0),
            Data = "",
            Uri = "",
            Thickness = 0,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("ImageLabel", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Image = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UICorner", {
                Name = "_CORNER",
                CornerRadius = UDim.new(0, 0)
            })
        })
    }, Image)

    table.insert(Drawing.__OBJECT_CACHE, ImageObject)

    return ImageObject
end

function Image:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Image[property]
end

function Image:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Data" then
        self:__SET_IMAGE(value)
    elseif property == "Uri" then
        self:__SET_IMAGE(value, true)
    elseif property == "Rounding" then
        self.__OBJECT._CORNER.CornerRadius = UDim.new(0, value)
    elseif property == "Color" then
        self.__OBJECT.ImageColor3 = value
    elseif property == "Position" then
        self.__OBJECT.Position = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Size" then
        self.__OBJECT.Size = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Transparency" then
        self.__OBJECT.ImageTransparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Image:__iter()
    return next, self.__PROPERTIES
end

function Image:__tostring()
    return "Drawing"
end

function Image:__SET_IMAGE(data, isUri)
    task.spawn(function()
        if isUri then
            data = HttpGet(game, data, true)
        end

        if not Drawing.__IMAGE_CACHE[data] then
            local TempPath = HttpService:GenerateGUID(false)

            writefile(TempPath, data)
            Drawing.__IMAGE_CACHE[data] = getcustomasset(TempPath)
            delfile(TempPath)
        end

        self.__PROPERTIES.Data = Drawing.__IMAGE_CACHE[data]
        self.__OBJECT.Image = Drawing.__IMAGE_CACHE[data]
    end)
end

function Image:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Image:Destroy()
    self:Remove()
end
--#endregion

--#region Triangle
local Triangle = {}

Drawing.__CLASSES["Triangle"] = Triangle

function Triangle.new()
    local TriangleObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            PointA = Vector2.new(0, 0),
            PointB = Vector2.new(0, 0),
            PointC = Vector2.new(0, 0),
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("Frame", {
                Name = "_A",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_B",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_C",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            })
        })
    }, Triangle)

    table.insert(Drawing.__OBJECT_CACHE, TriangleObject)

    return TriangleObject
end

function Triangle:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Triangle[property]
end

function Triangle:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties, Object = self.__PROPERTIES, self.__OBJECT

    Properties[property] = value

    if property == "Color" then
        Object._A.BackgroundColor3 = value
        Object._B.BackgroundColor3 = value
        Object._C.BackgroundColor3 = value
    elseif property == "Transparency" then
        Object._A.BackgroundTransparency = 1 - values
        Object._B.BackgroundTransparency = 1 - values
        Object._C.BackgroundTransparency = 1 - values
    elseif property == "Thickness" then
        Object._A.BackgroundColor3 = UDim2.fromOffset(Object._A.AbsoluteSize.X, math.max(value, 1));
        Object._B.BackgroundColor3 = UDim2.fromOffset(Object._B.AbsoluteSize.X, math.max(value, 1));
        Object._C.BackgroundColor3 = UDim2.fromOffset(Object._C.AbsoluteSize.X, math.max(value, 1));
    elseif property == "PointA" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._C, Properties.PointC, Properties.PointA }
        })
    elseif property == "PointB" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._B, Properties.PointB, Properties.PointC }
        })
    elseif property == "PointC" then
        self:__UPDATE_VERTICIES({
            { Object._B, Properties.PointB, Properties.PointC },
            { Object._C, Properties.PointC, Properties.PointA }
        })
    elseif property == "Visible" then
        Object.Visible = value
    elseif property == "ZIndex" then
        Object.ZIndex = value
    end
end

function Triangle:__iter()
    return next, self.__PROPERTIES
end

function Triangle:__tostring()
    return "Drawing"
end

function Triangle:__UPDATE_VERTICIES(verticies)
    local thickness = self.__PROPERTIES.Thickness

    for idx, verticy in verticies do
        Drawing.UpdatePosition(verticy[1], verticy[2], verticy[3], thickness)
    end
end

function Triangle:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Triangle:Destroy()
    self:Remove()
end
--#endregion

--#region Quad
local Quad = {}

Drawing.__CLASSES["Quad"] = Quad

function Quad.new()
    local QuadObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            PointA = Vector2.new(0, 0),
            PointB = Vector2.new(0, 0),
            PointC = Vector2.new(0, 0),
            PointD = Vector2.new(0, 0),
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("Frame", {
                Name = "_A",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_B",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_C",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_D",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            })
        })
    }, Quad)

    table.insert(Drawing.__OBJECT_CACHE, QuadObject)

    return QuadObject
end

function Quad:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Quad[property]
end

function Quad:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties, Object = self.__PROPERTIES, self.__OBJECT

    Properties[property] = value

    if property == "Color" then
        Object._A.BackgroundColor3 = value
        Object._B.BackgroundColor3 = value
        Object._C.BackgroundColor3 = value
        Object._D.BackgroundColor3 = value
    elseif property == "Transparency" then
        Object._A.BackgroundTransparency = 1 - values
        Object._B.BackgroundTransparency = 1 - values
        Object._C.BackgroundTransparency = 1 - values
        Object._D.BackgroundTransparency = 1 - values
    elseif property == "Thickness" then
        Object._A.BackgroundColor3 = UDim2.fromOffset(Object._A.AbsoluteSize.X, math.max(value, 1));
        Object._B.BackgroundColor3 = UDim2.fromOffset(Object._B.AbsoluteSize.X, math.max(value, 1));
        Object._C.BackgroundColor3 = UDim2.fromOffset(Object._C.AbsoluteSize.X, math.max(value, 1));
        Object._D.BackgroundColor3 = UDim2.fromOffset(Object._D.AbsoluteSize.X, math.max(value, 1));
    elseif property == "PointA" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._D, Properties.PointD, Properties.PointA }
        })
    elseif property == "PointB" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._B, Properties.PointB, Properties.PointC }
        })
    elseif property == "PointC" then
        self:__UPDATE_VERTICIES({
            { Object._B, Properties.PointB, Properties.PointC },
            { Object._C, Properties.PointC, Properties.PointD }
        })
    elseif property == "PointD" then
        self:__UPDATE_VERTICIES({
            { Object._C, Properties.PointC, Properties.PointD },
            { Object._D, Properties.PointD, Properties.PointA }
        })
    elseif property == "Visible" then
        Object.Visible = value
    elseif property == "ZIndex" then
        Object.ZIndex = value
    end
end

function Quad:__iter()
    return next, self.__PROPERTIES
end

function Quad:__tostring()
    return "Drawing"
end

function Quad:__UPDATE_VERTICIES(verticies)
    local thickness = self.__PROPERTIES.Thickness

    for idx, verticy in verticies do
        Drawing.UpdatePosition(verticy[1], verticy[2], verticy[3], thickness)
    end
end

function Quad:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Quad:Destroy()
    self:Remove()
end
--#endregion

if not isfolder("DrawingFontCache") then
    makefolder("DrawingFontCache")
end

Drawing.Font.new("UI", "rbxasset://fonts/families/Arial.json")
Drawing.Font.new("System", "rbxasset://fonts/families/HighwayGothic.json")
Drawing.Font.new("Plex", "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/oADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAWwBfAGMAZwBrAG8AcwB3AHsAfwCDAIcAiwCPAAARNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxWAgICAgICA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAAoCA/ICAgICAgICABICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAABwGAAAACAAQAAAMABwALAA8AEwAXABsAAAE1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQM1MxUBgICAgICAgICAgICAgIADgICAgICAgICAgICAgICAgICA/wCAgAAGAQADAAKABIAAAwAHAAsADwATABcAAAE1MxUzNTMVBTUzFTM1MxUFNTMVMzUzFQEAgICA/oCAgID+gICAgAQAgICAgICAgICAgICAgIAAABgAAAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwBXAFsAXwAAATUzFTM1MxUFNTMVMzUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVMzUzFQU1MxUzNTMVAYCAgID+gICAgP2AgICAgICA/YCAgID+gICAgP2AgICAgICA/YCAgID+gICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAFQCA/4ADAAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAAABNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVMTUzFTE1MxUFNTMVMzUzFQU1MxUzNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUBgID/AICAgID9gICAgP6AgICA/wCAgID/AICAgP6AgICA/YCAgICA/wCAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAUAAAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAATNTMVITUzFQU1MxUzNTMVMzUzFQU1MxUzNTMVMzUzFQU1MxUzNTMVBzUzFTM1MxUFNTMVMzUzFTM1MxUFNTMVMzUzFTM1MxUFNTMVITUzFYCAAYCA/QCAgICAgP2AgICAgID+AICAgICAgID+AICAgICA/YCAgICAgP0AgAGAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAFACAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAATUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUhNTMVBTUzFSE1MxUzNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTM1MxUBAICA/oCAAQCA/gCAAQCA/oCAgAEAgP0AgAEAgICA/QCAAYCA/YCAAYCA/gCAgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAMBgAMAAgAEgAADAAcACwAAATUzFQc1MxUHNTMVAYCAgICAgAQAgICAgICAgIAAAAsBAP8AAoAEgAADAAcACwAPABMAFwAbAB8AIwAnACsAAAE1MxUFNTMVBzUzFQU1MxUHNTMVBzUzFQc1MxUHNTMdATUzFQc1Mx0BNTMVAgCA/wCAgID/AICAgICAgICAgICAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAALAQD/AAKABIAAAwAHAAsADwATABcAGwAfACMAJwArAAABNTMdATUzFQc1Mx0BNTMVBzUzFQc1MxUHNTMVBzUzFQU1MxUHNTMVBTUzFQEAgICAgICAgICAgICAgP8AgICA/wCABACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAACwCAAIADAAMAAAMABwALAA8AEwAXABsAHwAjACcAKwAAATUzFQU1MxUzNTMVMzUzFQU1MxUxNTMVMTUzFQU1MxUzNTMVMzUzFQU1MxUBgID+gICAgICA/gCAgID+AICAgICA/oCAAoCAgICAgICAgICAgICAgICAgICAgICAgICAgAAACQCAAIADAAMAAAMABwALAA8AEwAXABsAHwAjAAABNTMVBzUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUBgICAgP6AgICAgID+gICAgAKAgICAgICAgICAgICAgICAgICAgICAgAAABACA/wABgAEAAAMABwALAA8AACU1MxUHNTMVBzUzFQU1MxUBAICAgICA/wCAgICAgICAgICAgICAAAAABQCAAYADAAIAAAMABwALAA8AEwAAEzUzFTE1MxUxNTMVMTUzFTE1MxWAgICAgIABgICAgICAgICAgIAAAgEAAAABgAEAAAMABwAAJTUzFQc1MxUBAICAgICAgICAgAAACgCA/4ADAASAAAMABwALAA8AEwAXABsAHwAjACcAAAE1MxUHNTMVBTUzFQc1MxUFNTMVBzUzFQU1MxUHNTMVBTUzFQc1MxUCgICAgP8AgICA/wCAgID/AICAgP8AgICABACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAUAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAABNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTM1MxUzNTMVBTUzFTM1MxUzNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQEAgICA/gCAAYCA/YCAAYCA/YCAgICAgP2AgICAgID9gIABgID9gIABgID+AICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAADgCAAAADAAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwAAATUzFQU1MxUxNTMVBTUzFTM1MxUHNTMVBzUzFQc1MxUHNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUBgID/AICA/oCAgICAgICAgICAgP6AgICAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAA8AgAAAAwAEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwAAATUzFTE1MxUxNTMVBTUzFSE1MxUHNTMVBTUzFQU1MxUFNTMVBTUzFQc1MxUxNTMVMTUzFTE1MxUxNTMVAQCAgID+AIABgICAgP8AgP8AgP8AgP8AgICAgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAPAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAAAE1MxUxNTMVMTUzFQU1MxUhNTMVBzUzFQU1MxUxNTMdATUzFQc1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQEAgICA/gCAAYCAgID+gICAgICA/YCAAYCA/gCAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAEQCAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwAAATUzFQU1MxUxNTMVBTUzFTM1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUCgID/AICA/oCAgID+AIABAID9gIABgID9gICAgICAgP8AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABIAgAAAAwAEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAEzUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUxNTMVMTUzFTE1Mx0BNTMVBzUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVgICAgICA/YCAgICAgICAgICAgP2AgAGAgP4AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAARAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAAABNTMVMTUzFQU1MxUFNTMVBzUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQGAgID+gID/AICAgICAgP4AgAGAgP2AgAGAgP2AgAGAgP4AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAADACAAAADAAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvAAATNTMVMTUzFTE1MxUxNTMVMTUzFQc1MxUFNTMVBzUzFQU1MxUHNTMVBTUzFQc1MxWAgICAgICAgP8AgICA/wCAgID/AICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAATAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwAAATUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQEAgICA/gCAAYCA/YCAAYCA/gCAgID+AIABgID9gIABgID9gIABgID+AICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAEQCAAAADAAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwAAATUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQc1MxUFNTMVBTUzFTE1MxUBAICAgP4AgAGAgP2AgAGAgP2AgAGAgP4AgICAgICA/wCA/oCAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAQBgAAAAgADAAADAAcACwAPAAABNTMVBzUzFQM1MxUHNTMVAYCAgICAgICAAoCAgICAgP6AgICAgIAAAAYAgP8AAYADAAADAAcACwAPABMAFwAAATUzFQc1MxUDNTMVBzUzFQc1MxUFNTMVAQCAgICAgICAgID/AIACgICAgICA/oCAgICAgICAgICAgAAAAAoAAACAAwADAAADAAcACwAPABMAFwAbAB8AIwAnAAABNTMVMTUzFQU1MxUxNTMVBTUzFTE1Mx0BNTMVMTUzHQE1MxUxNTMVAgCAgP4AgID+AICAgICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAAAAADACAAQADgAKAAAMABwALAA8AEwAXABsAHwAjACcAKwAvAAATNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxUBNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxWAgICAgICA/QCAgICAgIACAICAgICAgICAgICAgP8AgICAgICAgICAgICAAAAKAIAAgAOAAwAAAwAHAAsADwATABcAGwAfACMAJwAAEzUzFTE1Mx0BNTMVMTUzHQE1MxUxNTMVBTUzFTE1MxUFNTMVMTUzFYCAgICAgID+AICA/gCAgAKAgICAgICAgICAgICAgICAgICAgICAgICAAAAAAAoAgAAAAwAEAAADAAcACwAPABMAFwAbAB8AIwAnAAABNTMVMTUzFTE1MxUFNTMVITUzFQc1MxUFNTMVBTUzFQc1MxUDNTMVAQCAgID+AIABgICAgP8AgP8AgICAgIADgICAgICAgICAgICAgICAgICAgICAgICA/wCAgAAaAAAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwBbAF8AYwBnAAABNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVMTUzFTM1MxUFNTMVMzUzFTM1MxUzNTMVBTUzFTM1MxUzNTMVMzUzFQU1MxUhNTMVMTUzFTE1MxUFNTMdATUzFTE1MxUxNTMVMTUzFQEAgICA/gCAAYCA/QCAAQCAgICA/ICAgICAgICA/ICAgICAgICA/ICAAQCAgID9gICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABIAgAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzFTE1MxUFNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVAYCAgP8AgID+gIABAID+AIABAID+AICAgID9gIACAID9AIACAID9AIACAIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAGACAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAWwBfAAATNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxWAgICAgP4AgAGAgP2AgAGAgP2AgICAgID9gIACAID9AIACAID9AIACAID9AICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAADgCAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwAAATUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVBzUzFQc1MxUHNTMdATUzFSE1MxUFNTMVMTUzFTE1MxUBgICAgP4AgAGAgP0AgICAgICAgIABgID+AICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAUAIAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAATNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFYCAgICA/gCAAYCA/YCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAYCA/YCAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAATAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwAAEzUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVMTUzFYCAgICAgP2AgICAgICAgID+AICAgICAgICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAPAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAABM1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVBzUzFYCAgICAgP2AgICAgICAgID+AICAgICAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAASAIAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcAAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFQc1MxUHNTMVITUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQGAgICA/gCAAYCA/QCAgICAgAEAgICA/QCAAgCA/YCAAYCA/gCAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAFACAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAEzUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxWAgAIAgP0AgAIAgP0AgAIAgP0AgICAgICA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAgCAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAwBAAAAAoAEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAAATUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBTUzFTE1MxUxNTMVAQCAgID/AICAgICAgICAgICA/wCAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAADACAAAACgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvAAABNTMVMTUzFTE1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUFNTMVMTUzFTE1MxUBAICAgICAgICAgICAgICAgP4AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAARAIAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAAATNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMzUzFQU1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFYCAAgCA/QCAAYCA/YCAAQCA/gCAgID+gICAgP6AgAEAgP4AgAGAgP2AgAIAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAMAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AABM1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVMTUzFYCAgICAgICAgICAgICAgICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABoAAAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwBXAFsAXwBjAGcAABE1MxUxNTMVITUzFTE1MxUFNTMVMTUzFSE1MxUxNTMVBTUzFTM1MxUzNTMVMzUzFQU1MxUzNTMVMzUzFTM1MxUFNTMVITUzFSE1MxUFNTMVITUzFSE1MxUFNTMVITUzFQU1MxUhNTMVgIABgICA/ICAgAGAgID8gICAgICAgID8gICAgICAgID8gIABAIABAID8gIABAIABAID8gIACgID8gIACgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAYAIAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwBbAF8AABM1MxUxNTMVITUzFQU1MxUxNTMVITUzFQU1MxUzNTMVITUzFQU1MxUzNTMVITUzFQU1MxUhNTMVMzUzFQU1MxUhNTMVMzUzFQU1MxUhNTMVMTUzFQU1MxUhNTMVMTUzFYCAgAGAgP0AgIABgID9AICAgAEAgP0AgICAAQCA/QCAAQCAgID9AIABAICAgP0AgAGAgID9AIABgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABAAgAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AAABNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVAYCAgP6AgAEAgP2AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP2AgAEAgP6AgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAARAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAAATNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFYCAgICA/gCAAYCA/YCAAYCA/YCAAYCA/YCAgICA/gCAgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAEgCA/4ADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMzUzFQc1MxUBgICA/oCAAQCA/YCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/YCAAQCA/oCAgICAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAFACAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAEzUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxWAgICAgP4AgAGAgP2AgAGAgP2AgAGAgP2AgICAgP4AgAEAgP4AgAGAgP2AgAIAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAEgCAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMdATUzFTE1Mx0BNTMVMTUzHQE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUBAICAgID9gIACAID9AICAgICAgP0AgAIAgP2AgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAOAAAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3AAARNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFYCAgICAgID+AICAgICAgICAgICAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAASAIAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcAABM1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFYCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/YCAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAA4AAAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAABE1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTM1MxUFNTMVMzUzFQU1MxUHNTMVgAKAgPyAgAKAgP0AgAGAgP2AgAGAgP4AgICA/oCAgID/AICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAYAAAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwBbAF8AABE1MxUhNTMVBTUzFSE1MxUhNTMVBTUzFSE1MxUhNTMVBTUzFTM1MxUzNTMVMzUzFQU1MxUzNTMVMzUzFTM1MxUFNTMVMTUzFTM1MxUxNTMVBTUzFSE1MxUFNTMVITUzFYACgID8gIABAIABAID8gIABAIABAID8gICAgICAgID8gICAgICAgID9AICAgICA/YCAAYCA/YCAAYCAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABAAgAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AAATNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFQU1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVgIACAID9AIACAID9gIABAID+gICA/wCAgP6AgAEAgP2AgAIAgP0AgAIAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAwAAAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAAETUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTM1MxUFNTMVBzUzFQc1MxUHNTMVgAKAgPyAgAKAgP0AgAGAgP4AgICA/wCAgICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAASAIAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcAABM1MxUxNTMVMTUzFTE1MxUxNTMVMTUzFQc1MxUFNTMVBTUzFQU1MxUFNTMVBTUzFQc1MxUxNTMVMTUzFTE1MxUxNTMVMTUzFYCAgICAgICAgP8AgP8AgP8AgP8AgP8AgICAgICAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAADwEA/wACgASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AAABNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVMTUzFTE1MxUBAICAgP6AgICAgICAgICAgICAgICAgICAgICABACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAoAgP+AAwAEgAADAAcACwAPABMAFwAbAB8AIwAnAAATNTMVBzUzHQE1MxUHNTMdATUzFQc1Mx0BNTMVBzUzHQE1MxUHNTMVgICAgICAgICAgICAgICAgAQAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAA8BAP8AAoAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwAAATUzFTE1MxUxNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBTUzFTE1MxUxNTMVAQCAgICAgICAgICAgICAgICAgICAgID+gICAgAQAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAKAIABgAMABIAAAwAHAAsADwATABcAGwAfACMAJwAAATUzFQc1MxUFNTMVMzUzFQU1MxUzNTMVBTUzFSE1MxUFNTMVITUzFQGAgICA/wCAgID+gICAgP4AgAGAgP2AgAGAgAQAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAcAAP+AA4AAAAADAAcACwAPABMAFwAbAAAVNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVgICAgICAgICAgICAgICAgICAgICAgAACAQADgAIABIAAAwAHAAABNTMdATUzFQEAgIAEAICAgICAAAAQAIAAAAMAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFTE1MxUxNTMdATUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQEAgICAgP4AgICAgP2AgAGAgP2AgAGAgP4AgICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAATAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwAAEzUzFQc1MxUHNTMVBzUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFYCAgICAgICAgICA/gCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/YCAgICABACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAMAIAAAAMAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFQc1MxUHNTMVITUzFQU1MxUxNTMVMTUzFQEAgICA/gCAAYCA/YCAgICAgAGAgP4AgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAATAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwAAATUzFQc1MxUHNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQKAgICAgID+AICAgID9gIABgID9gIABgID9gIABgID9gIABgID+AICAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAEACAAAADAAMAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFSE1MxUFNTMVMTUzFTE1MxUBAICAgP4AgAGAgP2AgICAgID9gICAgAGAgP4AgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAADgCAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwAAATUzFTE1MxUxNTMVBTUzFQc1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVBzUzFQc1MxUBgICAgP4AgICA/wCAgICA/oCAgICAgICAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAVAID+gAMAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAAAE1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUHNTMVBzUzFQU1MxUxNTMVMTUzFQEAgICAgP2AgAGAgP2AgAGAgP2AgAGAgP2AgAGAgP4AgICAgICAgID+AICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAABEAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMAABM1MxUHNTMVBzUzFQc1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVgICAgICAgICAgID+AIABgID9gIABgID9gIABgID9gIABgID9gIABgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAACAEAAAACAASAAAMABwALAA8AEwAXABsAHwAAATUzFQE1MxUxNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUBgID/AICAgICAgICAgICAgAQAgID+gICAgICAgICAgICAgICAgICAgIAAAAAMAID/AAKABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AAAE1MxUBNTMVMTUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQU1MxUxNTMVMTUzFQIAgP8AgICAgICAgICAgICAgID+AICAgAQAgID+gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAQAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAEzUzFQc1MxUHNTMVBzUzFSE1MxUFNTMVITUzFQU1MxUzNTMVBTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFYCAgICAgICAAYCA/YCAAQCA/gCAgID+gICAgP6AgAEAgP4AgAGAgAQAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAKAQAAAAIABIAAAwAHAAsADwATABcAGwAfACMAJwAAATUzFTE1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQEAgICAgICAgICAgICAgICAgICABACAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAFAAAAAADgAMAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAETUzFTE1MxUxNTMVMzUzFTE1MxUFNTMVITUzFSE1MxUFNTMVITUzFSE1MxUFNTMVITUzFSE1MxUFNTMVITUzFSE1MxUFNTMVITUzFSE1MxWAgICAgID9AIABAIABAID8gIABAIABAID8gIABAIABAID8gIABAIABAID8gIABAIABAIACgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAA4AgAAAAwADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAABM1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVgICAgID+AIABgID9gIABgID9gIABgID9gIABgID9gIABgIACgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAA4AgAAAAwADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVAQCAgID+AIABgID9gIABgID9gIABgID9gIABgID+AICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABMAgP6AAwADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAAATNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVgICAgID+AIABgID9gIABgID9gIABgID9gIABgID9gICAgID+AICAgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABMAgP6AAwADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAAABNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVBzUzFQc1MxUHNTMVAQCAgICA/YCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/gCAgICAgICAgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAoAgAAAAwADAAADAAcACwAPABMAFwAbAB8AIwAnAAATNTMVMzUzFTE1MxUFNTMVMTUzFSE1MxUFNTMVBzUzFQc1MxUHNTMVgICAgID+AICAAQCA/YCAgICAgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAAA0AgAAAAwADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzAAABNTMVMTUzFTE1MxUxNTMVBTUzHQE1MxUxNTMdATUzHQE1MxUFNTMVMTUzFTE1MxUxNTMVAQCAgICA/YCAgICAgP2AgICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAA0BAAAAAwAEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzAAABNTMVBzUzFQc1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUHNTMdATUzFTE1MxUxNTMVAQCAgICAgICAgP4AgICAgICAgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAOAIAAAAMAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3AAATNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFYCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/gCAgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAKAIAAAAMAAwAAAwAHAAsADwATABcAGwAfACMAJwAAEzUzFSE1MxUFNTMVITUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVBzUzFYCAAYCA/YCAAYCA/gCAgID+gICAgP8AgICAAoCAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABIAAAAAA4ADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAETUzFSE1MxUFNTMVITUzFSE1MxUFNTMVITUzFSE1MxUFNTMVMzUzFTM1MxUzNTMVBTUzFTE1MxUzNTMVMTUzFQU1MxUhNTMVgAKAgPyAgAEAgAEAgPyAgAEAgAEAgPyAgICAgICAgP0AgICAgID9gIABgIACgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAKAIAAAAMAAwAAAwAHAAsADwATABcAGwAfACMAJwAAEzUzFSE1MxUFNTMVMzUzFQU1MxUHNTMVBTUzFTM1MxUFNTMVITUzFYCAAYCA/gCAgID/AICAgP8AgICA/gCAAYCAAoCAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABMAgP6AAwADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAAATNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQc1MxUHNTMVBTUzFTE1MxUxNTMVgIABgID9gIABgID9gIABgID9gIABgID9gIABgID+AICAgICAgICA/gCAgIACgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAOAIAAAAMAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3AAATNTMVMTUzFTE1MxUxNTMVMTUzFQc1MxUFNTMVBTUzFQU1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFYCAgICAgICA/wCA/wCA/wCA/wCAgICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAOAID/AAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3AAABNTMVMTUzFQU1MxUHNTMVBzUzFQc1MxUFNTMVMTUzHQE1MxUHNTMVBzUzFQc1Mx0BNTMVMTUzFQIAgID+gICAgICAgID+gICAgICAgICAgICABACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAsBgP8AAgAEgAADAAcACwAPABMAFwAbAB8AIwAnACsAAAE1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVAYCAgICAgICAgICAgICAgICAgICAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAOAID/AAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3AAATNTMVMTUzHQE1MxUHNTMVBzUzFQc1Mx0BNTMVMTUzFQU1MxUHNTMVBzUzFQc1MxUFNTMVMTUzFYCAgICAgICAgICAgP6AgICAgICAgP6AgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAAAgAAAGAA4ACgAADAAcACwAPABMAFwAbAB8AABM1MxUxNTMVMTUzFSE1MxUFNTMVITUzFTE1MxUxNTMVgICAgAEAgPyAgAEAgICAAgCAgICAgICAgICAgICAgICAgAAAABMAgAAAA4ADgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAAABNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVAYCAgID+AIABgID9AICAgID+gID/AICAgID+gIABgID+AICAgAMAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAABAEA/wACAAEAAAMABwALAA8AACU1MxUHNTMVBzUzFQU1MxUBgICAgICA/wCAgICAgICAgICAgICAAAAAEACA/wADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AAAE1MxUxNTMVBTUzFQc1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVBTUzFTE1MxUCAICA/oCAgID/AICAgID+gICAgICAgICAgICA/oCAgAQAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAYBAP+AAoABAAADAAcACwAPABMAFwAAJTUzFTM1MxUFNTMVMzUzFQU1MxUzNTMVAQCAgID+gICAgP6AgICAgICAgICAgICAgICAgICAAAAAAwCAAAADAACAAAMABwALAAAzNTMVMzUzFTM1MxWAgICAgICAgICAgIAAAAANAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwAAATUzFQc1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQGAgICA/oCAgICAgP6AgICAgICAgICAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAABEAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMAAAE1MxUHNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUHNTMVAYCAgID+gICAgICA/oCA/oCAgICAgP6AgICAgICAgAQAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAAAUAgAMAAwAEgAADAAcACwAPABMAAAE1MxUFNTMVMzUzFQU1MxUhNTMVAYCA/wCAgID+AIABgIAEAICAgICAgICAgICAgAAAAA4AgAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAAAE1MxUFNTMVITUzFQU1MxUzNTMVBzUzFQU1MxUHNTMVMzUzFTM1MxUFNTMVITUzFTM1MxUFNTMVAgCA/gCAAQCA/gCAgICAgP8AgICAgICAgP0AgAEAgICA/QCAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAVAIAAAAOABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAAAE1MxUzNTMVBTUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1Mx0BNTMVMTUzHQE1MxUxNTMdATUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQEAgICA/wCA/wCAgICA/YCAAgCA/QCAgICAgID9AIACAID9gICAgIAEgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAABQCAAIACAAMAAAMABwALAA8AEwAAATUzFQU1MxUFNTMdATUzHQE1MxUBgID/AID/AICAgAKAgICAgICAgICAgICAgIAAAAAAGAAAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAWwBfAAATNTMVMTUzFTM1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUzNTMVMTUzFTE1MxWAgICAgICA/ICAAQCA/gCAAQCA/gCAAQCAgID9AIABAID+AIABAID+AIABAID+gICAgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABUAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwAAATUzFTM1MxUFNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVBzUzFQU1MxUFNTMVBTUzFQU1MxUFNTMVBzUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVAQCAgID/AID+gICAgICAgICA/wCA/wCA/wCA/wCA/wCAgICAgICAgASAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAADAYADAAKABIAAAwAHAAsAAAE1MxUHNTMdATUzFQGAgICAgAQAgICAgICAgIAAAAADAQADAAIABIAAAwAHAAsAAAE1MxUHNTMVBTUzFQGAgICA/wCABACAgICAgICAgAAGAQADAAMABIAAAwAHAAsADwATABcAAAE1MxUzNTMVBTUzFTM1MxUFNTMVMzUzFQEAgICA/oCAgID/AICAgAQAgICAgICAgICAgICAgIAAAAYAgAMAAoAEgAADAAcACwAPABMAFwAAATUzFTM1MxUFNTMVMzUzFQU1MxUzNTMVAQCAgID+gICAgP4AgICABACAgICAgICAgICAgICAgAAADQCAAIADAAMAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMAAAE1MxUFNTMVMTUzFTE1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUxNTMVMTUzFQU1MxUBgID/AICAgP4AgICAgID+AICAgP8AgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAAAUAgAGAAwACAAADAAcACwAPABMAABM1MxUxNTMVMTUzFTE1MxUxNTMVgICAgICAAYCAgICAgICAgICAAAcAAAGAA4ACAAADAAcACwAPABMAFwAbAAARNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVgICAgICAgAGAgICAgICAgICAgICAgIAAAAAABACAAwACgAQAAAMABwALAA8AAAE1MxUzNTMVBTUzFTM1MxUBAICAgP4AgICAA4CAgICAgICAgIAAAAAAEAAAAgADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AABE1MxUxNTMVMTUzFTM1MxUxNTMVMTUzFQU1MxUhNTMVMTUzFTE1MxUFNTMVITUzFTM1MxUFNTMVITUzFTM1MxWAgICAgICA/QCAAQCAgID9AIABAICAgP0AgAEAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAQAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFTM1MxUFNTMVATUzFTE1MxUxNTMVMTUzFQU1Mx0BNTMVMTUzHQE1Mx0BNTMVBTUzFTE1MxUxNTMVMTUzFQEAgICA/wCA/wCAgICA/YCAgICAgP2AgICAgAQAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAFAIAAgAIAAwAAAwAHAAsADwATAAATNTMdATUzHQE1MxUFNTMVBTUzFYCAgID/AID/AIACgICAgICAgICAgICAgICAABUAAAAAA4ADAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwAAEzUzFTE1MxUzNTMVMTUzFQU1MxUhNTMVITUzFQU1MxUhNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFSE1MxUFNTMVMTUzFTM1MxUxNTMVgICAgICA/QCAAQCAAQCA/ICAAQCAgICA/ICAAQCA/gCAAQCAAQCA/QCAgICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAEQCAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwAAATUzFTM1MxUFNTMVATUzFTE1MxUxNTMVMTUzFTE1MxUHNTMVBTUzFQU1MxUFNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUBAICAgP8AgP6AgICAgICAgP8AgP8AgP8AgP8AgICAgIAEAICAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAADQAAAAADgASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMAAAE1MxUzNTMVATUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTM1MxUFNTMVBzUzFQc1MxUBAICAgP2AgAKAgPyAgAKAgP0AgAGAgP4AgICA/wCAgICAgAQAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAHAYAAAAIABAAAAwAHAAsADwATABcAGwAAATUzFQM1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQGAgICAgICAgICAgICAgAOAgID/AICAgICAgICAgICAgICAgICAABIAgP+AAwADgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzFQU1MxUxNTMVMTUzFQU1MxUzNTMVMzUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVMzUzFTM1MxUFNTMVMTUzFTE1MxUFNTMVAYCA/wCAgID+AICAgICA/YCAgID+gICAgP6AgICAgID+AICAgP8AgAMAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAQAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFTE1MxUFNTMVBzUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQU1MxUHNTMVMTUzFTE1MxUxNTMVMTUzFQGAgID+gICAgP8AgICAgP6AgICA/wCAgICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAUAAAAAAOAA4AAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAARNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVITUzFYACgID9AICAgICA/YCAAYCA/YCAAYCA/YCAAYCA/YCAgICAgP0AgAKAgAMAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABAAAAAAA4AEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AAARNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMzUzFQU1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVgAKAgPyAgAKAgP0AgAGAgP4AgICA/wCA/oCAgICAgP6AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAACgGA/wACAASAAAMABwALAA8AEwAXABsAHwAjACcAAAE1MxUHNTMVBzUzFQc1MxUHNTMVAzUzFQc1MxUHNTMVBzUzFQc1MxUBgICAgICAgICAgICAgICAgICAgIAEAICAgICAgICAgICAgICA/wCAgICAgICAgICAgICAgAAAAAASAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcAAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzHQE1MxUxNTMVBTUzFTM1MxUFNTMVMTUzHQE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQEAgICA/gCAAYCA/YCAgID/AICAgP8AgICA/YCAAYCA/gCAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAACAQAEAAKABIAAAwAHAAABNTMVMzUzFQEAgICABACAgICAAAAcAAAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwBbAF8AYwBnAGsAbwAAEzUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVMTUzFTM1MxUFNTMVMzUzFSE1MxUFNTMVMzUzFSE1MxUFNTMVITUzFTE1MxUzNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFYCAgICAgP0AgAKAgPyAgAEAgICAgPyAgICAAYCA/ICAgIABgID8gIABAICAgID8gIACgID9AICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAACwCAAYACgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAAATUzFTE1Mx0BNTMVBTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUBAICAgP6AgICA/gCAAQCA/oCAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAKAIAAgAMAAwAAAwAHAAsADwATABcAGwAfACMAJwAAATUzFTM1MxUFNTMVMzUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVMzUzFQGAgICA/gCAgID+AICAgP8AgICA/wCAgIACgICAgICAgICAgICAgICAgICAgICAgICAgAAABwCAAAACgAIAAAMABwALAA8AEwAXABsAABM1MxUxNTMVMTUzFTE1MxUHNTMVBzUzFQc1MxWAgICAgICAgICAgAGAgICAgICAgICAgICAgICAgIAAHgAAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAWwBfAGMAZwBrAG8AcwB3AAATNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFTM1MxUxNTMVITUzFQU1MxUzNTMVMzUzFTM1MxUFNTMVMzUzFTE1MxUhNTMVBTUzFTM1MxUzNTMVMzUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxWAgICAgID9AIACgID8gICAgIABAID8gICAgICAgID8gICAgIABAID8gICAgICAgID8gIACgID9AICAgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAABwAABIADgAUAAAMABwALAA8AEwAXABsAABE1MxUxNTMVMTUzFTE1MxUxNTMVMTUzFTE1MxWAgICAgICABICAgICAgICAgICAgICAgAAAAAAIAIACgAKABIAAAwAHAAsADwATABcAGwAfAAABNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFQEAgID+gIABAID+AIABAID+gICABACAgICAgICAgICAgICAgICAgICAAAAAAA4AgAAAAwADgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAAAE1MxUHNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFQE1MxUxNTMVMTUzFTE1MxUxNTMVAYCAgID+gICAgICA/oCAgID+gICAgICAAwCAgICAgICAgICAgICAgICAgICAgICA/wCAgICAgICAgICAAAoAgAIAAoAEgAADAAcACwAPABMAFwAbAB8AIwAnAAATNTMVMTUzFTE1Mx0BNTMVBTUzFQU1MxUFNTMVMTUzFTE1MxUxNTMVgICAgID/AID/AID/AICAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgAAACgCAAgACgASAAAMABwALAA8AEwAXABsAHwAjACcAABM1MxUxNTMVMTUzHQE1MxUFNTMVMTUzHQE1MxUFNTMVMTUzFTE1MxWAgICAgP6AgICA/gCAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgAAAAAACAYADgAKABIAAAwAHAAABNTMVBTUzFQIAgP8AgAQAgICAgIAAAAAAEQAA/wADgAMAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwAAEzUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFSE1MxUFNTMVMzUzFTE1MxUzNTMVBTUzFQU1MxWAgAGAgP2AgAGAgP2AgAGAgP2AgAGAgP2AgIABAID9gICAgICAgP0AgP8AgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAGgCA/4ADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAWwBfAGMAZwAAATUzFTE1MxUxNTMVMTUzFTE1MxUFNTMVMTUzFTE1MxUzNTMVBTUzFTE1MxUxNTMVMzUzFQU1MxUxNTMVMzUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVMzUzFQU1MxUzNTMVBTUzFTM1MxUBAICAgICA/QCAgICAgP2AgICAgID+AICAgID+gICAgP6AgICA/oCAgID+gICAgP6AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAJAQABAAKAAoAAAwAHAAsADwATABcAGwAfACMAAAE1MxUxNTMVMTUzFQU1MxUxNTMVMTUzFQU1MxUxNTMVMTUzFQEAgICA/oCAgID+gICAgAIAgICAgICAgICAgICAgICAgICAgIAAAAQBgP6AAoAAAAADAAcACwAPAAAFNTMVMTUzFQc1MxUFNTMVAYCAgICA/wCAgICAgICAgICAgIAACACAAgACAASAAAMABwALAA8AEwAXABsAHwAAATUzFQU1MxUxNTMVBzUzFQc1MxUFNTMVMTUzFTE1MxUBAID/AICAgICAgP8AgICABACAgICAgICAgICAgICAgICAgICAgAAAAAoAgAIAAoAEgAADAAcACwAPABMAFwAbAB8AIwAnAAABNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVAQCAgP6AgAEAgP4AgAEAgP4AgAEAgP6AgIAEAICAgICAgICAgICAgICAgICAgICAgICAgAAKAIAAgAMAAwAAAwAHAAsADwATABcAGwAfACMAJwAAEzUzFTM1MxUFNTMVMzUzFQU1MxUzNTMVBTUzFTM1MxUFNTMVMzUzFYCAgID/AICAgP8AgICA/gCAgID+AICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAAAAAFgCAAAADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAAAE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMzUzFQc1MxUFNTMVITUzFQU1MxUzNTMVMTUzFQU1MxUzNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUCgID9gIABgID9gIABAID+AIABAID+AICAgICA/wCAAQCA/gCAgICA/YCAgICAgID9AIABgIAEgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABYAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwBXAAABNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTM1MxUHNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFTE1MxUxNTMVAoCA/YCAAYCA/YCAAQCA/gCAAQCA/gCAgICAgICA/gCAAYCA/YCAAQCA/YCAAQCA/gCAAQCAgIAEgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAaAAAAAAOABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwBbAF8AYwBnAAABNTMVBTUzFTE1MxUhNTMVBTUzFTM1MxUFNTMVMTUzFTM1MxUFNTMVMTUzFQU1MxUxNTMVMzUzFQU1MxUhNTMVBTUzFTM1MxUxNTMVBTUzFTM1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQKAgP0AgIABgID+AICAgP4AgICAgP6AgID+AICAgID/AIABAID+AICAgID9gICAgICAgP0AgAGAgASAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAKAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwAAATUzFQM1MxUHNTMVBTUzFQU1MxUHNTMVITUzFQU1MxUxNTMVMTUzFQGAgICAgID/AID/AICAgAGAgP4AgICAA4CAgP8AgICAgICAgICAgICAgICAgICAgICAgIAAEgCAAAADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMdATUzFQE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUBgICA/wCAgP6AgAEAgP4AgAEAgP4AgICAgP2AgAIAgP0AgAIAgP0AgAIAgASAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAASAIAAAAOABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcAAAE1MxUFNTMVAzUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQIAgP8AgICAgP6AgAEAgP4AgAEAgP4AgICAgP2AgAIAgP0AgAIAgP0AgAIAgASAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABQAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AAAE1MxUxNTMVBTUzFSE1MxUBNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVAYCAgP6AgAEAgP6AgID+gIABAID+AIABAID+AICAgID9gIACAID9AIACAID9AIACAIAEgICAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAFACAAAADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAATUzFTM1MxUFNTMVMzUzFQE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUBgICAgP4AgICA/wCAgP6AgAEAgP4AgAEAgP4AgICAgP2AgAIAgP0AgAIAgP0AgAIAgASAgICAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAASAIAAAAOABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcAAAE1MxUhNTMVATUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQEAgAEAgP6AgID+gIABAID+AIABAID+AICAgID9gIACAID9AIACAID9AIACAIAEAICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABYAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwBXAAABNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVAYCAgP6AgAEAgP4AgAEAgP6AgID+gIABAID+AIABAID+AICAgID9gIACAID9AIACAID9AIACAIAEgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAXAAAAAAOABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwBbAAABNTMVMTUzFTE1MxUxNTMVBTUzFTM1MxUFNTMVMzUzFQU1MxUhNTMVMTUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUxNTMVMTUzFQGAgICAgP2AgICA/oCAgID+AIABAICA/YCAgICA/YCAAYCA/YCAAYCA/YCAAYCAgIADgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAEQCA/oADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwAAATUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVBzUzFQc1MxUHNTMdATUzFSE1MxUFNTMVMTUzFTE1MxUFNTMVBzUzFQU1MxUBgICAgP4AgAGAgP0AgICAgICAgIABgID+AICAgP8AgICA/wCAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAUAIAAAAMABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAABNTMdATUzFQE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVMTUzFQEAgID+gICAgICA/YCAgICAgICAgP4AgICAgICAgICABICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAUAIAAAAMABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAABNTMVBTUzFQE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVMTUzFQIAgP8AgP6AgICAgID9gICAgICAgICA/gCAgICAgICAgIAEgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAFQCAAAADAAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAAABNTMVBTUzFTM1MxUBNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFTE1MxUxNTMVMTUzFTE1MxUBgID/AICAgP4AgICAgID9gICAgICAgICA/gCAgICAgICAgIAEgICAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAFACAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAATUzFTM1MxUBNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFTE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFTE1MxUxNTMVMTUzFTE1MxUBAICAgP4AgICAgID9gICAgICAgICA/gCAgICAgICAgIAEAICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAADQEAAAACgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMAAAE1Mx0BNTMVATUzFTE1MxUxNTMVBTUzFQc1MxUHNTMVBzUzFQc1MxUFNTMVMTUzFTE1MxUBgICA/oCAgID/AICAgICAgICAgP8AgICABICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgAANAQAAAAKABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwAAATUzFQU1MxUBNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUHNTMVBzUzFQU1MxUxNTMVMTUzFQIAgP8AgP8AgICA/wCAgICAgICAgID/AICAgASAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAOAQAAAAKABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3AAABNTMVBTUzFTM1MxUBNTMVMTUzFTE1MxUFNTMVBzUzFQc1MxUHNTMVBzUzFQU1MxUxNTMVMTUzFQGAgP8AgICA/oCAgID/AICAgICAgICAgP8AgICABICAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAAA0BAAAAAoAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzAAABNTMVMzUzFQE1MxUxNTMVMTUzFQU1MxUHNTMVBzUzFQc1MxUHNTMVBTUzFTE1MxUxNTMVAQCAgID+gICAgP8AgICAgICAgICA/wCAgIAEAICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAFQAAAAADgAOAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAAATNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxWAgICAgP4AgAGAgP2AgAIAgPyAgICAgAEAgP0AgAIAgP0AgAGAgP2AgICAgAMAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABkAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AUwBXAFsAXwBjAAABNTMVMzUzFQU1MxUzNTMVATUzFTE1MxUhNTMVBTUzFTM1MxUhNTMVBTUzFTM1MxUhNTMVBTUzFSE1MxUzNTMVBTUzFSE1MxUzNTMVBTUzFSE1MxUxNTMVBTUzFSE1MxUxNTMVAYCAgID+AICAgP4AgIABgID9AICAgAEAgP0AgICAAQCA/QCAAQCAgID9AIABAICAgP0AgAGAgID9AIABgICABICAgICAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABAAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AAABNTMdATUzFQE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVAYCAgP8AgID+gIABAID9gIACAID9AIACAID9AIACAID9gIABAID+gICABICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAQAIAAAAOABQAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFQU1MxUDNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFQIAgP8AgICAgP6AgAEAgP2AgAIAgP0AgAIAgP0AgAIAgP2AgAEAgP6AgIAEgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAEgCAAAADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVMTUzFQU1MxUhNTMVATUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUBgICA/oCAAQCA/oCAgP6AgAEAgP2AgAIAgP0AgAIAgP0AgAIAgP2AgAEAgP6AgIAEgICAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAEgCAAAADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVMzUzFQU1MxUzNTMVATUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUBgICAgP4AgICA/wCAgP6AgAEAgP2AgAIAgP0AgAIAgP0AgAIAgP2AgAEAgP6AgIAEgICAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAEACAAAADgASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AAAE1MxUhNTMVATUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUBAIABAID+gICA/oCAAQCA/YCAAgCA/QCAAgCA/QCAAgCA/YCAAQCA/oCAgAQAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAkAgACAAwADAAADAAcACwAPABMAFwAbAB8AIwAAEzUzFSE1MxUFNTMVMzUzFQU1MxUFNTMVMzUzFQU1MxUhNTMVgIABgID+AICAgP8AgP8AgICA/gCAAYCAAoCAgICAgICAgICAgICAgICAgICAgICAAAAAFgCAAAADgAQAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAAAE1MxUxNTMVMzUzFQU1MxUhNTMVBTUzFSE1MxUzNTMVBTUzFSE1MxUzNTMVBTUzFTM1MxUhNTMVBTUzFTM1MxUhNTMVBTUzFSE1MxUFNTMVMzUzFTE1MxUBgICAgID9gIABAID9gIABAICAgP0AgAEAgICA/QCAgIABAID9AICAgAEAgP2AgAEAgP2AgICAgAOAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABIAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzHQE1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVAYCAgP4AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP2AgICAgASAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABIAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzFQU1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVAgCA/wCA/oCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/QCAAgCA/YCAgICABICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAABQAgAAAA4AFAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAE8AAAE1MxUxNTMVBTUzFSE1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVAYCAgP6AgAEAgP2AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP0AgAIAgP2AgICAgASAgICAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAEgCAAAADgASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVITUzFQE1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUBAIABAID9gIACAID9AIACAID9AIACAID9AIACAID9AIACAID9AIACAID9gICAgIAEAICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAADQAAAAADgAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMAAAE1MxUFNTMVATUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTM1MxUFNTMVBzUzFQc1MxUCAID/AID+AIACgID8gIACgID9AIABgID+AICAgP8AgICAgIAEgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAQAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAEzUzFQc1MxUHNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVBzUzFYCAgICAgICAgP4AgAGAgP2AgAGAgP2AgICAgP4AgICAA4CAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAAGQAA/4ADgASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwBTAFcAWwBfAGMAAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFQU1MxUBAICAgP4AgAGAgP2AgAGAgP2AgICAgP4AgAGAgP2AgAIAgP0AgAIAgP0AgAIAgP0AgICAgID9AIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABIAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzHQE1MxUBNTMVMTUzFTE1Mx0BNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVAYCAgP6AgICAgP4AgICAgP2AgAGAgP2AgAGAgP4AgICAgAQAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAEgCAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVBTUzFQE1MxUxNTMVMTUzHQE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUCAID/AID/AICAgID+AICAgID9gIABgID9gIABgID+AICAgIAEAICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAEwCAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsAAAE1MxUFNTMVMzUzFQE1MxUxNTMVMTUzHQE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUBgID/AICAgP6AgICAgP4AgICAgP2AgAGAgP2AgAGAgP4AgICAgAQAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAUAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAABNTMVMzUzFQU1MxUzNTMVATUzFTE1MxUxNTMdATUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQGAgICA/gCAgID+gICAgID+AICAgID9gIABgID9gIABgID+AICAgIAEAICAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABIAgAAAAwAEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzFTM1MxUBNTMVMTUzFTE1Mx0BNTMVBTUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVAQCAgID+gICAgID+AICAgID9gIABgID9gIABgID+AICAgIADgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAFACAAAADAAUAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAATUzFQU1MxUzNTMVBTUzFQE1MxUxNTMVMTUzHQE1MxUFNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUBgID/AICAgP8AgP8AgICAgP4AgICAgP2AgAGAgP2AgAGAgP4AgICAgASAgICAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAWAAAAAAOAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAVwAAEzUzFTE1MxUzNTMVMTUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFSE1MxUFNTMVMTUzFTE1MxUxNTMVMTUzFYCAgICAgP6AgAEAgP0AgICAgICA/ICAAQCA/gCAAQCAAQCA/QCAgICAgAKAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAPAID+gAMAAwAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAAAE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFQc1MxUHNTMVITUzFQU1MxUxNTMVMTUzFQU1MxUHNTMVBTUzFQEAgICA/gCAAYCA/YCAgICAgAGAgP4AgICA/wCAgID/AIACgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABIAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzHQE1MxUBNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUhNTMVBTUzFTE1MxUxNTMVAQCAgP8AgICA/gCAAYCA/YCAgICAgP2AgICAAYCA/gCAgIAEAICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABIAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzFQU1MxUDNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUhNTMVBTUzFTE1MxUxNTMVAYCA/wCAgICAgP4AgAGAgP2AgICAgID9gICAgAGAgP4AgICABACAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABMAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwBLAAABNTMVBTUzFTM1MxUBNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUhNTMVBTUzFTE1MxUxNTMVAYCA/wCAgID+gICAgP4AgAGAgP2AgICAgID9gICAgAGAgP4AgICABACAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAABIAgAAAAwAEAAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMARwAAATUzFTM1MxUBNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1MxUxNTMVBTUzFQc1MxUhNTMVBTUzFTE1MxUxNTMVAQCAgID+gICAgP4AgAGAgP2AgICAgID9gICAgAGAgP4AgICAA4CAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAAAkBAAAAAgAEgAADAAcACwAPABMAFwAbAB8AIwAAATUzHQE1MxUBNTMVMTUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVAQCAgP8AgICAgICAgICAgICABACAgICAgP8AgICAgICAgICAgICAgICAgICAgAAJAQAAAAIABIAAAwAHAAsADwATABcAGwAfACMAAAE1MxUFNTMVAzUzFTE1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQGAgP8AgICAgICAgICAgICAgIAEAICAgICA/wCAgICAgICAgICAgICAgICAgICAAAAAAAoBAAAAAoAEgAADAAcACwAPABMAFwAbAB8AIwAnAAABNTMVBTUzFTM1MxUBNTMVMTUzFQc1MxUHNTMVBzUzFQc1MxUHNTMVAYCA/wCAgID+gICAgICAgICAgICAgAQAgICAgICAgP8AgICAgICAgICAgICAgICAgICAgAAJAQAAAAKABIAAAwAHAAsADwATABcAGwAfACMAAAE1MxUzNTMVATUzFTE1MxUHNTMVBzUzFQc1MxUHNTMVBzUzFQEAgICA/oCAgICAgICAgICAgIAEAICAgID+gICAgICAgICAgICAgICAgICAgIAAFACAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAEsATwAAATUzFTE1MxUzNTMVBTUzFQU1MxUzNTMVBzUzFQU1MxUxNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUBAICAgID/AID/AICAgICA/gCAgICA/YCAAYCA/YCAAYCA/YCAAYCA/gCAgIAEAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAEgCAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVMzUzFQU1MxUzNTMVATUzFTE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUBAICAgP4AgICA/oCAgICA/gCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/YCAAYCABACAgICAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAQAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzHQE1MxUBNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQEAgID/AICAgP4AgAGAgP2AgAGAgP2AgAGAgP2AgAGAgP4AgICABACAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAABAAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AAABNTMVBTUzFQE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVAgCA/wCA/wCAgID+AIABgID9gIABgID9gIABgID9gIABgID+AICAgAQAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAABEAgAAAAwAEgAADAAcACwAPABMAFwAbAB8AIwAnACsALwAzADcAOwA/AEMAAAE1MxUFNTMVMzUzFQE1MxUxNTMVMTUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVAYCA/wCAgID+gICAgP4AgAGAgP2AgAGAgP2AgAGAgP2AgAGAgP4AgICABACAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAEgCAAAADAASAAAMABwALAA8AEwAXABsAHwAjACcAKwAvADMANwA7AD8AQwBHAAABNTMVMzUzFQU1MxUzNTMVATUzFTE1MxUxNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVMTUzFTE1MxUBgICAgP4AgICA/oCAgID+AIABgID9gIABgID9gIABgID9gIABgID+AICAgAQAgICAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAQAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFTM1MxUBNTMVMTUzFTE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFQEAgICA/oCAgID+AIABgID9gIABgID9gIABgID9gIABgID+AICAgAOAgICAgP8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAcAgACAAwADAAADAAcACwAPABMAFwAbAAABNTMVATUzFTE1MxUxNTMVMTUzFTE1MxUBNTMVAYCA/oCAgICAgP6AgAKAgID/AICAgICAgICAgID/AICAAAAUAID/gAMAA4AAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAAABNTMVBTUzFTE1MxUxNTMVBTUzFSE1MxUxNTMVBTUzFTM1MxUzNTMVBTUzFTM1MxUzNTMVBTUzFTE1MxUhNTMVBTUzFTE1MxUxNTMVBTUzFQKAgP4AgICA/gCAAQCAgP2AgICAgID9gICAgICA/YCAgAEAgP4AgICA/gCAAwCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAQAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzHQE1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQEAgID+gIABgID9gIABgID9gIABgID9gIABgID9gIABgID+AICAgIAEAICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAQAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFQU1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQGAgP8AgP8AgAGAgP2AgAGAgP2AgAGAgP2AgAGAgP2AgAGAgP4AgICAgAQAgICAgID/AICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAARAIAAAAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAAABNTMVBTUzFTM1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQGAgP8AgICA/gCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/gCAgICABACAgICAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAQAIAAAAMABAAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwAAATUzFTM1MxUBNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFTE1MxUxNTMVMTUzFQEAgICA/gCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/YCAAYCA/gCAgICAA4CAgICA/wCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAAAAAVAID+gAMABIAAAwAHAAsADwATABcAGwAfACMAJwArAC8AMwA3ADsAPwBDAEcASwBPAFMAAAE1MxUFNTMVATUzFSE1MxUFNTMVITUzFQU1MxUhNTMVBTUzFSE1MxUFNTMVITUzFQU1MxUxNTMVMTUzFTE1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MDAxMA51bmljb2RlIzB4MDAxMQ51bmljb2RlIzB4MDAxMg51bmljb2RlIzB4MDAxMw51bmljb2RlIzB4MDAxNA51bmljb2RlIzB4MDAxNQ51bmljb2RlIzB4MDAxNg51bmljb2RlIzB4MDAxNw51bmljb2RlIzB4MDAxOA51bmljb2RlIzB4MDAxOQ51bmljb2RlIzB4MDAxYQ51bmljb2RlIzB4MDAxYg51bmljb2RlIzB4MDAxYw51bmljb2RlIzB4MDAxZA51bmljb2RlIzB4MDAxZQ51bmljb2RlIzB4MDAxZgZkZWxldGUERXVybw51bmljb2RlIzB4MDA4MQ51bmljb2RlIzB4MDA4Mg51bmljb2RlIzB4MDA4Mw51bmljb2RlIzB4MDA4NA51bmljb2RlIzB4MDA4NQ51bmljb2RlIzB4MDA4Ng51bmljb2RlIzB4MDA4Nw51bmljb2RlIzB4MDA4OA51bmljb2RlIzB4MDA4OQ51bmljb2RlIzB4MDA4YQ51bmljb2RlIzB4MDA4Yg51bmljb2RlIzB4MDA4Yw51bmljb2RlIzB4MDA4ZA51bmljb2RlIzB4MDA4ZQ51bmljb2RlIzB4MDA4Zg51bmljb2RlIzB4MDA5MA51bmljb2RlIzB4MDA5MQ51bmljb2RlIzB4MDA5Mg51bmljb2RlIzB4MDA5Mw51bmljb2RlIzB4MDA5NA51bmljb2RlIzB4MDA5NQ51bmljb2RlIzB4MDA5Ng51bmljb2RlIzB4MDA5Nw51bmljb2RlIzB4MDA5OA51bmljb2RlIzB4MDA5OQ51bmljb2RlIzB4MDA5YQ51bmljb2RlIzB4MDA5Yg51bmljb2RlIzB4MDA5Yw51bmljb2RlIzB4MDA5ZA51bmljb2RlIzB4MDA5ZQ51bmljb2RlIzB4MDA5ZgAA")
Drawing.Font.new("Monospace", "rbxasset://fonts/families/RobotoMono.json")
Drawing.Font.new("Pixel", "AAEAAAAMAIAAAwBAT1MvMmSz/H0AAAFIAAAAYFZETVhoYG/3AAAGmAAABeBjbWFwel+AIwAADHgAAAUwZ2FzcP//AAEAAGP4AAAACGdseWa90hIhAAARqAAARRRoZWFk/hqSzwAAAMwAAAA2aGhlYQegBbsAAAEEAAAAJGhtdHhmdgAAAAABqAAABPBsb2Nh73HeDAAAVrwAAAJ6bWF4cAFBADMAAAEoAAAAIG5hbWX/R4pVAABZOAAABC1wb3N0fPqooAAAXWgAAAaOAAEAAAABAAArGZw2Xw889QAJA+gAAAAAzSamLgAAAADNJqljAAD/OASwAyAAAAAJAAIAAAAAAAAAAQAAAu7/BgAABRQAAABkBLAAAQAAAAAAAAAAAAAAAAAAATwAAQAAATwAMgAEAAAAAAABAAAAAAAAAAAAAAAAAAAAAAADAfMBkAAFAAACvAKKAAD/nAK8AooAAAD6ADIA+gAAAgAAAAAAAAAAAIAAAi8AAAAKAAAAAAAAAABQWVJTAEAAICEiAu7/BgAAAyAAyAAAAAUAAAAAAPoB9AAAACAAAAH0AAAAAAAAAfQAAAH0AAACWAAAAlgAAAJYAAAAyAAAAS0AAAEtAAABkAAAAZAAAAEsAAABkAAAAMgAAAJYAAAB9AAAAZAAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAMgAAAEsAAABkAAAAZAAAAGQAAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAZAAAAH0AAAB9AAAAfQAAAJYAAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAABkAAAAfQAAAGQAAACWAAAAfQAAAGQAAAB9AAAASwAAAJYAAABLAAAAlgAAAH0AAABLAAAAfQAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAABkAAAAfQAAAH0AAAB9AAAAlgAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAfQAAAGQAAAB9AAAAZAAAAJYAAAB9AAAAZAAAAH0AAABkAAAAMgAAAGQAAAB9AAAAlgAAAH0AAABLAAAAfQAAAJYAAACWAAAAZAAAAGQAAACWAAAAyAAAAJYAAABkAAAAlgAAAH0AAACWAAAAZAAAAJYAAABLAAAASwAAAJYAAACWAAAASwAAAGQAAAB9AAAA4QAAAJYAAABkAAAAlgAAAH0AAACWAAAAZAAAAGQAAABkAAAAfQAAAH0AAAB9AAAAMgAAAH0AAAB9AAAAyAAAAH0AAACvAAAAfQAAAEsAAADIAAAAZAAAAGQAAABkAAAAZAAAAGQAAAB9AAAAlgAAAJYAAAAyAAAAfQAAAK8AAAB9AAAArwAAAH0AAAB9AAAAfQAAAGQAAAB9AAAAfQAAAH0AAAB9AAAAlgAAAH0AAACWAAAAfQAAAH0AAAB9AAAAfQAAAH0AAACWAAAAfQAAAH0AAAB9AAAAfQAAAH0AAABkAAAAfQAAAJYAAAB9AAAAlgAAAH0AAACWAAAArwAAAJYAAACvAAAAfQAAAH0AAACWAAAAfQAAAH0AAAB9AAAAfQAAAH0AAACWAAAAfQAAAJYAAAB9AAAAfQAAAH0AAAB9AAAAfQAAAJYAAAB9AAAAfQAAAH0AAAB9AAAAfQAAAGQAAAB9AAAAlgAAAH0AAACWAAAAfQAAAJYAAACvAAAAlgAAAK8AAAB9AAAAfQAAAJYAAAB9AAAAfQAAAH0AAAAyAAAAlgAAAH0AAABkAAAAZAAAAH0AAAB9AAAAfQAAAEsAAABkAAAAZAAAAH0AAAFFAAABRQAAAUUAAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAlgAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAZAAAAGQAAABkAAAAZAAAAJYAAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAABkAAAAlgAAAH0AAAB9AAAAfQAAAH0AAABkAAAAfQAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAACWAAAAfQAAAH0AAAB9AAAAfQAAAH0AAABkAAAAZAAAAGQAAABkAAAAlgAAAH0AAAB9AAAAfQAAAH0AAAB9AAAAfQAAAGQAAACWAAAAfQAAAH0AAAB9AAAAfQAAAGQAAAB9AAAAZAAAAJYAAACWAAAAfQAAAH0AAABkAAAAfQAAAH0AAAB9AAAAZAAAAH0AAACWAAAAMgAAAGQAAAAAAABAAEBAQEBAAwA+Aj/AAgAB//+AAkACP/+AAoACP/+AAsACf/9AAwACv/9AA0AC//9AA4ADP/9AA8ADP/9ABAADf/8ABEADv/8ABIAD//8ABMAEP/8ABQAEP/8ABUAEf/7ABYAEv/7ABcAE//7ABgAFP/7ABkAFP/7ABoAFf/6ABsAFv/6ABwAF//6AB0AGP/6AB4AGP/6AB8AGf/5ACAAGv/5ACEAG//5ACIAHP/5ACMAHP/5ACQAHf/4ACUAHv/4ACYAH//4ACcAIP/4ACgAIP/4ACkAIf/3ACoAIv/3ACsAI//3ACwAJP/3AC0AJP/3AC4AJf/2AC8AJv/2ADAAJ//2ADEAKP/2ADIAKP/2ADMAKf/1ADQAKv/1ADUAK//1ADYALP/1ADcALP/1ADgALf/0ADkALv/0ADoAL//0ADsAMP/0ADwAMP/0AD0AMf/zAD4AMv/zAD8AM//zAEAANP/zAEEANP/zAEIANf/yAEMANv/yAEQAN//yAEUAOP/yAEYAOP/yAEcAOf/xAEgAOv/xAEkAO//xAEoAPP/xAEsAPP/xAEwAPf/wAE0APv/wAE4AP//wAE8AQP/wAFAAQP/wAFEAQf/vAFIAQv/vAFMAQ//vAFQARP/vAFUARP/vAFYARf/uAFcARv/uAFgAR//uAFkASP/uAFoASP/uAFsASf/tAFwASv/tAF0AS//tAF4ATP/tAF8ATP/tAGAATf/sAGEATv/sAGIAT//sAGMAUP/sAGQAUP/sAGUAUf/rAGYAUv/rAGcAU//rAGgAVP/rAGkAVP/rAGoAVf/qAGsAVv/qAGwAV//qAG0AWP/qAG4AWP/qAG8AWf/pAHAAWv/pAHEAW//pAHIAXP/pAHMAXP/pAHQAXf/oAHUAXv/oAHYAX//oAHcAYP/oAHgAYP/oAHkAYf/nAHoAYv/nAHsAY//nAHwAZP/nAH0AZP/nAH4AZf/mAH8AZv/mAIAAZ//mAIEAaP/mAIIAaP/mAIMAaf/lAIQAav/lAIUAa//lAIYAbP/lAIcAbP/lAIgAbf/kAIkAbv/kAIoAb//kAIsAcP/kAIwAcP/kAI0Acf/jAI4Acv/jAI8Ac//jAJAAdP/jAJEAdP/jAJIAdf/iAJMAdv/iAJQAd//iAJUAeP/iAJYAeP/iAJcAef/hAJgAev/hAJkAe//hAJoAfP/hAJsAfP/hAJwAff/gAJ0Afv/gAJ4Af//gAJ8AgP/gAKAAgP/gAKEAgf/fAKIAgv/fAKMAg//fAKQAhP/fAKUAhP/fAKYAhf/eAKcAhv/eAKgAh//eAKkAiP/eAKoAiP/eAKsAif/dAKwAiv/dAK0Ai//d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ATkBOgE7ATwBPQE+AT8BQAFBAUIBQwFEAUUBRgFHAUgBSQFKAUsBTAFNAU4BTwFQAVEBUgFTAVQBVQFWAVcBWAFZAVoBWwFcAV0BXgFfAWABYQFiAWMBZAFlAWYAowCEAIUAlgCOAJ0A8gDzAI0A3gDxAJ4A9QD0APYAogCtAMkAxwCuAGIAYwCQAGQAywBlAMgAygDPAMwAzQDOAOkAZgDTANAA0QCvAGcA8ACRANYA1ADVAGgA6wDtAIkAagBpAGsAbQBsAG4AoABvAHEAcAByAHMAdQB0AHYAdwDqAHgAegB5AHsAfQB8ALgAoQB/AH4AgACBAOwA7gC6ALAAsQDkAOUAuwDmAOcApgDYANkABgAEAAUFLm51bGwJYWZpaTEwMDUxCWFmaWkxMDA1MglhZmlpMTAxMDAERXVybwlhZmlpMTAwNTgJYWZpaTEwMDU5CWFmaWkxMDA2MQlhZmlpMTAwNjAJYWZpaTEwMTQ1CWFmaWkxMDA5OQlhZmlpMTAxMDYJYWZpaTEwMTA3CWFmaWkxMDEwOQlhZmlpMTAxMDgJYWZpaTEwMTkzCWFmaWkxMDA2MglhZmlpMTAxMTAJYWZpaTEwMDU3CWFmaWkxMDA1MAlhZmlpMTAwMjMJYWZpaTEwMDUzB3VuaTAwQUQJYWZpaTEwMDU2CWFmaWkxMDA1NQlhZmlpMTAxMDMJYWZpaTEwMDk4DnBlcmlvZGNlbnRlcmVkCWFmaWkxMDA3MQlhZmlpNjEzNTIJYWZpaTEwMTAxCWFmaWkxMDEwNQlhZmlpMTAwNTQJYWZpaTEwMTAyCWFmaWkxMDEwNAlhZmlpMTAwMTcJYWZpaTEwMDE4CWFmaWkxMDAxOQlhZmlpMTAwMjAJYWZpaTEwMDIxCWFmaWkxMDAyMglhZmlpMTAwMjQJYWZpaTEwMDI1CWFmaWkxMDAyNglhZmlpMTAwMjcJYWZpaTEwMDI4CWFmaWkxMDAyOQlhZmlpMTAwMzAJYWZpaTEwMDMxCWFmaWkxMDAzMglhZmlpMTAwMzMJYWZpaTEwMDM0CWFmaWkxMDAzNQlhZmlpMTAwMzYJYWZpaTEwMDM3CWFmaWkxMDAzOAlhZmlpMTAwMzkJYWZpaTEwMDQwCWFmaWkxMDA0MQlhZmlpMTAwNDIJYWZpaTEwMDQzCWFmaWkxMDA0NAlhZmlpMTAwNDUJYWZpaTEwMDQ2CWFmaWkxMDA0NwlhZmlpMTAwNDgJYWZpaTEwMDQ5CWFmaWkxMDA2NQlhZmlpMTAwNjYJYWZpaTEwMDY3CWFmaWkxMDA2OAlhZmlpMTAwNjkJYWZpaTEwMDcwCWFmaWkxMDA3MglhZmlpMTAwNzMJYWZpaTEwMDc0CWFmaWkxMDA3NQlhZmlpMTAwNzYJYWZpaTEwMDc3CWFmaWkxMDA3OAlhZmlpMTAwNzkJYWZpaTEwMDgwCWFmaWkxMDA4MQlhZmlpMTAwODIJYWZpaTEwMDgzCWFmaWkxMDA4NAlhZmlpMTAwODUJYWZpaTEwMDg2CWFmaWkxMDA4NwlhZmlpMTAwODgJYWZpaTEwMDg5CWFmaWkxMDA5MAlhZmlpMTAwOTEJYWZpaTEwMDkyCWFmaWkxMDA5MwlhZmlpMTAwOTQJYWZpaTEwMDk1CWFmaWkxMDA5NglhZmlpMTAwOTcNYWZpaTEwMDQ1LjAwMQ1hZmlpMTAwNDcuMDAxAAAAAAAB//8AAA==")

local cleardrawcache = Drawing.ClearCache

local DrawingDict = Instance.new("ScreenGui", game:GetService("CoreGui")) -- For drawing.new
local Drawings = {} -- for cleardrawcache
local Fonts = { -- Drawing.Fonts
 [0] = Enum.Font.Arial,
 [1] = Enum.Font.BuilderSans,
 [2] = Enum.Font.Gotham,
 [3] = Enum.Font.RobotoMono
}
local Drawing = {};
Drawing.Fonts = {
  ['UI'] = 0,
  ['System'] = 1,
  ['Plex'] = 2,
  ['Monospace'] = 3
}
local function cleardrawcache()
    for _, v in pairs(Drawings) do
        v:Remove()
    end
    table.clear(Drawings)
end
local function isrenderobj(thing)
    return Drawings[thing] ~= nil
end
Drawing.new = function(Type) -- Drawing.new
    local baseProps = {
     Visible = false,
     Color = Color3.new(0,0,0),
     ClassName = nil
    }
    if Type == 'Line' then
        local a = Instance.new("Frame", Instance.new("ScreenGui", DrawingDict))
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Thickness = 1,
            From = Vector2.new(0, 0),
            To = Vector2.new(0, 0),
            Transparency = 0,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateLine = function(self)
             if not a then return end
             local from = self.From
             local to = self.To
             local distance = (to - from).Magnitude
             local angle = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))

             a.Size = UDim2.new(0, distance, 0, self.Thickness)
             a.Position = UDim2.new(0, from.X, 0, from.Y)
             a.Rotation = angle
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Thickness' and typeof(value) == 'number' then
                rawset(self, key, value)
                a.Size = UDim2.new(0, (self.To - self.From).Magnitude, 0, value)
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
                a.BackgroundColor3 = value
            elseif key == 'Transparency' and typeof(value) == 'number' and value <= 1 then
                rawset(self, key, value)
                a.BackgroundTransparency = 1 - value
            elseif key == 'From' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateLine()
            elseif key == 'To' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateLine()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Square' then
        local a = Instance.new("Frame", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        local b = Instance.new("UIStroke", a)
        b.Color = Color3.fromRGB(255, 255, 255)
        b.Enabled = true

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Size = Vector2.new(0,0),
            Position = Vector2.new(0, 0),
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateSquare = function(self)
             if not a then return end
             a.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Filled' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                b.Enabled = not value
                a.BackgroundTransparency = value and 0 or 1
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
                a.BackgroundColor3 = value
                b.Color = value
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateSquare()
            elseif key == 'Size' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateSquare()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Circle' then
        local a = Instance.new("Frame", Instance.new("ScreenGui", DrawingDict))
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        local b = Instance.new("UIStroke", a)
        b.Color = Color3.fromRGB(255, 255, 255)
        b.Enabled = false
        b.Thickness = 1
        local c = Instance.new("UICorner", a)
        c.CornerRadius = UDim.new(1, 0)

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Thickness = 1,
            Filled = false,
            NumSides = 0,
            Radius = 1,
            Position = Vector2.new(0, 0),
            Transparency = 0,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateCircle = function(self)
             if not b or not a then return end
             a.Size = UDim2.new(0, self.Radius, 0, self.Radius)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             b.Enabled = not self
             b.Color = self.Color
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Thickness' and typeof(value) == 'number' then
                rawset(self, key, value)
                b.Thickness = value
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
                a.BackgroundColor3 = value
                a.Color = value
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
                a.BackgroundTransparency = 1 - value
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateCircle()
            elseif key == 'Radius' and typeof(value) == 'number' then
                rawset(self, key, value)
                self:updateCircle()
            elseif key == 'NumSides' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Filled' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                self:updateCircle()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Text' then
        local a = Instance.new("TextLabel", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        a.TextStrokeColor3 = Color3.new(0,0,0)
        a.TextStrokeTransparency = 1

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Text = '',
            Transparency = 0,
            Size = 0,
            Center = false,
            Outline = false,
            OutlineColor = Color3.new(0,0,0),
            Position = Vector2.new(0,0),
            Font = 3,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateText = function(self)
             if not a then return end
             a.TextScaled = true
             a.Size = UDim2.new(0, self.Size * 3, 0, self.Size / 2)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             a.Text = self.Text
             a.Font = Fonts[self.Font]
             a.Visible = self.Visible
             a.TextColor3 = self.Color or Color3.new(0, 0, 0)
             a.TextTransparency = 1 - self.Transparency
             a.BorderSizePixel = self.Outline and 1 or 0
             if self.Center then
              a.TextXAlignment = Enum.TextXAlignment.Center
              a.TextYAlignment = Enum.TextYAlignment.Center
             else
              a.TextXAlignment = Enum.TextXAlignment.Left
              a.TextYAlignment = Enum.TextYAlignment.Top
             end
             a.TextStrokeTransparency = self.Outline and 0 or 1
             a.TextStrokeColor3 = self.OutlineColor
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Text' and typeof(value) == 'string' then
                rawset(self, key, value)
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
            elseif key == 'Size' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Outline' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'Center' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'OutlineColor' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Font' and typeof(value) == 'number' then
                rawset(self, key, value)
            end
            self:updateText()
        end

        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Image' then
        local a = Instance.new("ImageLabel", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.ImageColor3 = Color3.fromRGB(255,255,255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0

        local meta = baseProps
        meta.ClassName = 'Image'
        meta.__index = {
            Text = '',
            Transparency = 0,
            Size = Vector2.new(0, 0),
            Position = Vector2.new(0,0),
            Color = Color3.fromRGB(255, 255, 255),
            Image = '',
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy()
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do
                if v == meta then Drawings[i] = nil end
               end
               a:Destroy()
            end,
            updateImage = function(self)
             if not a then return end
             a.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             a.Visible = self.Visible
             a.ImageColor3 = self.Color
             a.ImageTransparency = 1 - self.Transparency
             a.BorderSizePixel = self.Outline and 1 or 0
             a.Image = self.Image
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
            elseif key == 'Size' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Image' and typeof(value) == 'string' then
                rawset(self, key, value)
            else
             return
            end
            self:updateImage()
        end

        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    end
end
-- Definitions
--yes its pasted but who cares
local _ing2 = 'skibidi toliet ohio sigma rizz'; 
local _ing1 = string.gmatch(_ing2, _ing2) 

local table = table.clone(table) -- Prevent modifications from other scripts
local debug = table.clone(debug) -- ^^^^
local bit32 = table.clone(bit32)
local bit = bit32
local os = table.clone(os)
local math = table.clone(math)
local utf8 = table.clone(utf8)
local string = table.clone(string)
local task = table.clone(task)

local game = game -- game is game
local oldGame = game

local Version = '1.1.6'

local isDragging = false -- rconsole
local dragStartPos = nil -- rconsole
local frameStartPos = nil -- rconsole

local Data = game:GetService("TeleportService"):GetLocalPlayerTeleportData()
local TeleportData
if Data and Data.MOREUNCSCRIPTQUEUE then
 TeleportData = Data.MOREUNCSCRIPTQUEUE
end
if TeleportData then
 local func = loadstring(TeleportData)
 local s, e = pcall(func)
 if not s then task.spawn(error, e) end
end


print = print
warn = warn
error = error
pcall = pcall
printidentity = printidentity
ipairs = ipairs
pairs = pairs
tostring = tostring
tonumber = tonumber
setmetatable = setmetatable
rawget = rawget
rawset = rawset
getmetatable = getmetatable
type = type
version = version

-- Services / Instances
local HttpService = game:GetService('HttpService');
local Log = game:GetService('LogService');

-- Load proprerties (CREDITS TO DEUCES ON DISCORD)
local API_Dump_Url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json"
local API_Dump = game:HttpGet(API_Dump_Url)
local Hidden = {}

for _, API_Class in pairs(HttpService:JSONDecode(API_Dump).Classes) do
    for _, Member in pairs(API_Class.Members) do
        if Member.MemberType == "Property" then
            local PropertyName = Member.Name

            local MemberTags = Member.Tags

            local Special

            if MemberTags then
                Special = table.find(MemberTags, "NotScriptable")
            end
            if Special then
                table.insert(Hidden, PropertyName)
            end
        end
    end
end

local vim = Instance.new("VirtualInputManager");

local DrawingDict = Instance.new("ScreenGui") -- For drawing.new

local ClipboardUI = Instance.new("ScreenGui") -- For setclipboard

local hui = Instance.new("Folder") -- For gethui
hui.Name = '\0'

local ClipboardBox = Instance.new('TextBox', ClipboardUI) -- For setclipboard
ClipboardBox.Position = UDim2.new(100, 0, 100, 0) -- VERY off screen

-- All the following are for rconsole
local Console = Instance.new("ScreenGui")
local ConsoleFrame = Instance.new("Frame")
local Topbar = Instance.new("Frame")
local _CORNER = Instance.new("UICorner")
local ConsoleCorner = Instance.new("UICorner")
local CornerHide = Instance.new("Frame")
local DontModify = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local CornerHide2 = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local UIPadding = Instance.new("UIPadding")
local ConsoleIcon = Instance.new("ImageLabel")
local Holder = Instance.new("ScrollingFrame")
local MessageTemplate = Instance.new("TextLabel")
local InputTemplate = Instance.new("TextBox")
local UIListLayout = Instance.new("UIListLayout")
local HolderPadding = Instance.new("UIPadding")

Console.Name = "Console"
Console.Parent = nil
Console.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ConsoleFrame.Name = "ConsoleFrame"
ConsoleFrame.Parent = Console
ConsoleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConsoleFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ConsoleFrame.BorderSizePixel = 0
ConsoleFrame.Position = UDim2.new(0.0963890627, 0, 0.220791712, 0)
ConsoleFrame.Size = UDim2.new(0, 888, 0, 577)

Topbar.Name = "Topbar"
Topbar.Parent = ConsoleFrame
Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Topbar.BorderColor3 = Color3.fromRGB(0, 0, 0)
Topbar.BorderSizePixel = 0
Topbar.Position = UDim2.new(0, 0, -0.000463640812, 0)
Topbar.Size = UDim2.new(1, 0, 0, 32)

_CORNER.Name = "_CORNER"
_CORNER.Parent = Topbar

ConsoleCorner.Name = "ConsoleCorner"
ConsoleCorner.Parent = ConsoleFrame

CornerHide.Name = "CornerHide"
CornerHide.Parent = ConsoleFrame
CornerHide.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CornerHide.BorderColor3 = Color3.fromRGB(0, 0, 0)
CornerHide.BorderSizePixel = 0
CornerHide.Position = UDim2.new(0, 0, 0.0280000009, 0)
CornerHide.Size = UDim2.new(1, 0, 0, 12)

DontModify.Name = "DontModify"
DontModify.Parent = ConsoleFrame
DontModify.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DontModify.BorderColor3 = Color3.fromRGB(0, 0, 0)
DontModify.BorderSizePixel = 0
DontModify.Position = UDim2.new(0.98169291, 0, 0.0278581586, 0)
DontModify.Size = UDim2.new(-0.00675675692, 21, 0.972141862, 0)

UICorner.Parent = DontModify

CornerHide2.Name = "CornerHide2"
CornerHide2.Parent = ConsoleFrame
CornerHide2.AnchorPoint = Vector2.new(1, 0)
CornerHide2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CornerHide2.BorderColor3 = Color3.fromRGB(0, 0, 0)
CornerHide2.BorderSizePixel = 0
CornerHide2.Position = UDim2.new(1, 0, 0.0450000018, 0)
CornerHide2.Size = UDim2.new(0, 9, 0.955023408, 0)

Title.Name = "Title"
Title.Parent = ConsoleFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0.0440017432, 0, 0, 0)
Title.Size = UDim2.new(0, 164, 0, 30)
Title.Font = Enum.Font.GothamMedium
Title.Text = "rconsole title"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17.000
Title.TextXAlignment = Enum.TextXAlignment.Left

UIPadding.Parent = Title
UIPadding.PaddingTop = UDim.new(0, 5)

ConsoleIcon.Name = "ConsoleIcon"
ConsoleIcon.Parent = ConsoleFrame
ConsoleIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ConsoleIcon.BackgroundTransparency = 1.000
ConsoleIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
ConsoleIcon.BorderSizePixel = 0
ConsoleIcon.Position = UDim2.new(0.00979213417, 0, 0.000874322082, 0)
ConsoleIcon.Size = UDim2.new(0, 31, 0, 31)
ConsoleIcon.Image = "http://www.roblox.com/asset/?id=11843683545"

Holder.Name = "Holder"
Holder.Parent = ConsoleFrame
Holder.Active = true
Holder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Holder.BackgroundTransparency = 1.000
Holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
Holder.BorderSizePixel = 0
Holder.Position = UDim2.new(0, 0, 0.054600548, 0)
Holder.Size = UDim2.new(1, 0, 0.945399463, 0)
Holder.ScrollBarThickness = 8
Holder.CanvasSize = UDim2.new(0,0,0,0)
Holder.AutomaticCanvasSize = Enum.AutomaticSize.XY

MessageTemplate.Name = "MessageTemplate"
MessageTemplate.Parent = Holder
MessageTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MessageTemplate.BackgroundTransparency = 1.000
MessageTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
MessageTemplate.BorderSizePixel = 0
MessageTemplate.Size = UDim2.new(0.9745, 0, 0.030000001, 0)
MessageTemplate.Visible = false
MessageTemplate.Font = Enum.Font.RobotoMono
MessageTemplate.Text = "TEMPLATE"
MessageTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
MessageTemplate.TextSize = 20.000
MessageTemplate.TextXAlignment = Enum.TextXAlignment.Left
MessageTemplate.TextYAlignment = Enum.TextYAlignment.Top
MessageTemplate.RichText = true

UIListLayout.Parent = Holder
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

HolderPadding.Name = "HolderPadding"
HolderPadding.Parent = Holder
HolderPadding.PaddingLeft = UDim.new(0, 15)
HolderPadding.PaddingTop = UDim.new(0, 15)

InputTemplate.Name = "InputTemplate"
InputTemplate.Parent = nil
InputTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InputTemplate.BackgroundTransparency = 1.000
InputTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
InputTemplate.BorderSizePixel = 0
InputTemplate.Size = UDim2.new(0.9745, 0, 0.030000001, 0)
InputTemplate.Visible = false
InputTemplate.RichText = true
InputTemplate.Font = Enum.Font.RobotoMono
InputTemplate.Text = ""
InputTemplate.PlaceholderText = ''
InputTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
InputTemplate.TextSize = 20.000
InputTemplate.TextXAlignment = Enum.TextXAlignment.Left
InputTemplate.TextYAlignment = Enum.TextYAlignment.Top

-- Variables
local Identity = -1
local active = true
-- Others
local oldLoader = loadstring
-- Empty Tables
local clonerefs = {}
local protecteduis = {}
local gc = {}
local Instances = {} -- for nil instances
local funcs = {} -- main table
local names = {} -- protected gui names
local cache = {} -- for cached instances
local Drawings = {} -- for cleardrawcache
-- Non empty tables
local colors = {
	BLACK = Color3.fromRGB(50, 50, 50),
	BLUE = Color3.fromRGB(0, 0, 204),
	GREEN = Color3.fromRGB(0, 255, 0),
	CYAN = Color3.fromRGB(0, 255, 255),
	RED = Color3.fromHex('#5A0101'),
	MAGENTA = Color3.fromRGB(255, 0, 255),
	BROWN = Color3.fromRGB(165, 42, 42),
	LIGHT_GRAY = Color3.fromRGB(211, 211, 211),
	DARK_GRAY = Color3.fromRGB(169, 169, 169),
	LIGHT_BLUE = Color3.fromRGB(173, 216, 230),
	LIGHT_GREEN = Color3.fromRGB(144, 238, 144),
	LIGHT_CYAN = Color3.fromRGB(224, 255, 255),
	LIGHT_RED = Color3.fromRGB(255, 204, 203),
	LIGHT_MAGENTA = Color3.fromRGB(255, 182, 193),
	YELLOW = Color3.fromRGB(255, 255, 0),
	WHITE = Color3.fromRGB(255, 255, 255),
	ORANGE = Color3.fromRGB(255, 186, 12)
}
local patterns = {
    { pattern = '(%w+)%s*%+=%s*(%w+)', format = "%s = %s + %s" },
    { pattern = '(%w+)%s*%-=%s*(%w+)', format = "%s = %s - %s" },
    { pattern = '(%w+)%s*%*=%s*(%w+)', format = "%s = %s * %s" },
    { pattern = '(%w+)%s*/=%s*(%w+)', format = "%s = %s / %s" }
}
local patterns2 = {
 { pattern = 'for%s+(%w+)%s*,%s*(%w+)%s*in%s*(%w+)%s*do', format = "for %s, %s in pairs(%s) do" }
}
local renv = {
    print, warn, error, assert, collectgarbage, load, require, select, tonumber, tostring, type, xpcall, pairs, next, ipairs,
    newproxy, rawequal, rawget, rawset, rawlen, setmetatable, PluginManager,
    coroutine.create, coroutine.resume, coroutine.running, coroutine.status, coroutine.wrap, coroutine.yield,
    bit32.arshift, bit32.band, bit32.bnot, bit32.bor, bit32.btest, bit32.extract, bit32.lshift, bit32.replace, bit32.rshift, bit32.xor,
    math.abs, math.acos, math.asin, math.atan, math.atan2, math.ceil, math.cos, math.cosh, math.deg, math.exp, math.floor, math.fmod, math.frexp, math.ldexp, math.log, math.log10, math.max, math.min, math.modf, math.pow, math.rad, math.random, math.randomseed, math.sin, math.sinh, math.sqrt, math.tan, math.tanh,
    string.byte, string.char, string.find, string.format, string.gmatch, string.gsub, string.len, string.lower, string.match, string.pack, string.packsize, string.rep, string.reverse, string.sub, string.unpack, string.upper,
    table.concat, table.insert, table.pack, table.remove, table.sort, table.unpack,
    utf8.char, utf8.charpattern, utf8.codepoint, utf8.codes, utf8.len, utf8.nfdnormalize, utf8.nfcnormalize,
    os.clock, os.date, os.difftime, os.time,
    delay, elapsedTime, require, spawn, tick, time, typeof, UserSettings, version, wait,
    task.defer, task.delay, task.spawn, task.wait,
    debug.traceback, debug.profilebegin, debug.profileend
}
local keys={[0x08]=Enum.KeyCode.Backspace,[0x09]=Enum.KeyCode.Tab,[0x0C]=Enum.KeyCode.Clear,[0x0D]=Enum.KeyCode.Return,[0x10]=Enum.KeyCode.LeftShift,[0x11]=Enum.KeyCode.LeftControl,[0x12]=Enum.KeyCode.LeftAlt,[0x13]=Enum.KeyCode.Pause,[0x14]=Enum.KeyCode.CapsLock,[0x1B]=Enum.KeyCode.Escape,[0x20]=Enum.KeyCode.Space,[0x21]=Enum.KeyCode.PageUp,[0x22]=Enum.KeyCode.PageDown,[0x23]=Enum.KeyCode.End,[0x24]=Enum.KeyCode.Home,[0x2D]=Enum.KeyCode.Insert,[0x2E]=Enum.KeyCode.Delete,[0x30]=Enum.KeyCode.Zero,[0x31]=Enum.KeyCode.One,[0x32]=Enum.KeyCode.Two,[0x33]=Enum.KeyCode.Three,[0x34]=Enum.KeyCode.Four,[0x35]=Enum.KeyCode.Five,[0x36]=Enum.KeyCode.Six,[0x37]=Enum.KeyCode.Seven,[0x38]=Enum.KeyCode.Eight,[0x39]=Enum.KeyCode.Nine,[0x41]=Enum.KeyCode.A,[0x42]=Enum.KeyCode.B,[0x43]=Enum.KeyCode.C,[0x44]=Enum.KeyCode.D,[0x45]=Enum.KeyCode.E,[0x46]=Enum.KeyCode.F,[0x47]=Enum.KeyCode.G,[0x48]=Enum.KeyCode.H,[0x49]=Enum.KeyCode.I,[0x4A]=Enum.KeyCode.J,[0x4B]=Enum.KeyCode.K,[0x4C]=Enum.KeyCode.L,[0x4D]=Enum.KeyCode.M,[0x4E]=Enum.KeyCode.N,[0x4F]=Enum.KeyCode.O,[0x50]=Enum.KeyCode.P,[0x51]=Enum.KeyCode.Q,[0x52]=Enum.KeyCode.R,[0x53]=Enum.KeyCode.S,[0x54]=Enum.KeyCode.T,[0x55]=Enum.KeyCode.U,[0x56]=Enum.KeyCode.V,[0x57]=Enum.KeyCode.W,[0x58]=Enum.KeyCode.X,[0x59]=Enum.KeyCode.Y,[0x5A]=Enum.KeyCode.Z,[0x5D]=Enum.KeyCode.Menu,[0x60]=Enum.KeyCode.KeypadZero,[0x61]=Enum.KeyCode.KeypadOne,[0x62]=Enum.KeyCode.KeypadTwo,[0x63]=Enum.KeyCode.KeypadThree,[0x64]=Enum.KeyCode.KeypadFour,[0x65]=Enum.KeyCode.KeypadFive,[0x66]=Enum.KeyCode.KeypadSix,[0x67]=Enum.KeyCode.KeypadSeven,[0x68]=Enum.KeyCode.KeypadEight,[0x69]=Enum.KeyCode.KeypadNine,[0x6A]=Enum.KeyCode.KeypadMultiply,[0x6B]=Enum.KeyCode.KeypadPlus,[0x6D]=Enum.KeyCode.KeypadMinus,[0x6E]=Enum.KeyCode.KeypadPeriod,[0x6F]=Enum.KeyCode.KeypadDivide,[0x70]=Enum.KeyCode.F1,[0x71]=Enum.KeyCode.F2,[0x72]=Enum.KeyCode.F3,[0x73]=Enum.KeyCode.F4,[0x74]=Enum.KeyCode.F5,[0x75]=Enum.KeyCode.F6,[0x76]=Enum.KeyCode.F7,[0x77]=Enum.KeyCode.F8,[0x78]=Enum.KeyCode.F9,[0x79]=Enum.KeyCode.F10,[0x7A]=Enum.KeyCode.F11,[0x7B]=Enum.KeyCode.F12,[0x90]=Enum.KeyCode.NumLock,[0x91]=Enum.KeyCode.ScrollLock,[0xBA]=Enum.KeyCode.Semicolon,[0xBB]=Enum.KeyCode.Equals,[0xBC]=Enum.KeyCode.Comma,[0xBD]=Enum.KeyCode.Minus,[0xBE]=Enum.KeyCode.Period,[0xBF]=Enum.KeyCode.Slash,[0xC0]=Enum.KeyCode.Backquote,[0xDB]=Enum.KeyCode.LeftBracket,[0xDD]=Enum.KeyCode.RightBracket,[0xDE]=Enum.KeyCode.Quote} -- for keypress
local Fonts = { -- Drawing.Fonts
 [0] = Enum.Font.Arial,
 [1] = Enum.Font.BuilderSans,
 [2] = Enum.Font.Gotham,
 [3] = Enum.Font.RobotoMono
}
-- rconsole
local MessageColor = colors['WHITE']
local ConsoleClone = nil
-- functions
local function Descendants(tbl)
    local descendants = {}
    
    local function process_table(subtbl, prefix)
        for k, v in pairs(subtbl) do
            local index = prefix and (prefix .. "." .. tostring(k)) or tostring(k)
            descendants[index] = v
            if type(v) == 'table' then
                process_table(v, index)
            else
                descendants[index] = v
            end
        end
    end

    if type(tbl) ~= 'table' then
        descendants[tostring(1)] = tbl
    else
        process_table(tbl, nil)
    end
    
    return descendants
end

local function rawlength(tbl)
 local a = 0
 for i, v in pairs(tbl) do
  a = a + 1
 end
 return a
end

local function ToPairsLoop(code)
    for _, p in ipairs(patterns2) do
        code = code:gsub(p.pattern, function(var1, var2, tbl)
            return p.format:format(var1, var2, tbl)
        end)
    end
    return code
end

local function SafeOverride(a, b, c) --[[ Index, Data, Should override ]]
    if getgenv()[a] and not c then return 1 end
    getfenv(0)[a] = b

    return 2
end

local function toluau(code)
    for _, p in ipairs(patterns) do
        code = code:gsub(p.pattern, function(var, value)
            return p.format:format(var, var, value)
        end)
    end
    code = ToPairsLoop(code)
    return code
end

local function handleInput(input, Object)
    if isDragging then
        local delta = input.Position - dragStartPos
        Object.Position = UDim2.new(
            frameStartPos.X.Scale, 
            frameStartPos.X.Offset + delta.X, 
            frameStartPos.Y.Scale, 
            frameStartPos.Y.Offset + delta.Y
        )
    end
end

local function startDrag(input, Object)
    isDragging = true
    dragStartPos = input.Position
    frameStartPos = Object.Position
    input.UserInputState = Enum.UserInputState.Begin
end

local function stopDrag(input)
    isDragging = false
    input.UserInputState = Enum.UserInputState.End
end

-- Main Functions
function QueueGetIdentity()
printidentity()
  task.wait(.1)
  local messages = Log:GetLogHistory()
  local message;
  if not messages[#messages].message:match("Current identity is") then
   for i = #messages, 1, -1 do
    if messages[i].message:match("Current identity is %d") then
     message = messages[i].message
     break
    end
   end
  else
   message = messages[#messages].message:match('Current identity is %d'):gsub("Current identity is ", '')
  end
  Identity = tonumber(message)
end
local Queue = {}
Queue.__index = Queue
function Queue.new()
    local self = setmetatable({}, Queue)
    self.elements = {}
    return self
end

function Queue:Queue(element)
    table.insert(self.elements, element)
end

function Queue:Update()
    if #self.elements == 0 then
        return nil
    end
    return table.remove(self.elements, 1)
end

function Queue:IsEmpty()
    return #self.elements == 0
end
function Queue:Current()
    return self.elements
end

-- Events
game.DescendantRemoving:Connect(function(des)
 table.insert(Instances, des)
 cache[des] = 'REMOVE'
end)
game.DescendantAdded:Connect(function(des)
 cache[des] = true
end)
game:GetService("UserInputService").WindowFocused:Connect(function()
 active = true
end)

game:GetService("UserInputService").WindowFocusReleased:Connect(function()
 active = false
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if not input then return end
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement and ConsoleClone then
        handleInput(input, ConsoleClone.ConsoleFrame)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if not input then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        stopDrag(input)
    end
end)
-- Libraries
funcs.base64 = {}
funcs.crypt = {hex={},url={}}
funcs.syn = {}
funcs.syn_backup = {}
funcs.http = {}
funcs.Drawing = {}
funcs.cache = {}
funcs.debug = debug
funcs.debug.getinfo = function(t)
    local CurrentLine = tonumber(debug.info(t, 'l'))
    local Source = debug.info(t, 's')
    local name = debug.info(t, 'n')
    local numparams, isvrg = debug.info(t, 'a')
    if #name == 0 then name = nil end
    local a, b = debug.info(t, 'a')
    return {
     ['currentline'] = CurrentLine,
     ['source'] = Source,
     ['name'] = tostring(name),
     ['numparams'] = tonumber(numparams),
     ['is_vararg'] = isvrg and 1 or 0,
     ['short_src'] = tostring(Source:sub(1, 60)),
     ['what'] = Source == '[C]' and 'C' or 'Lua',
     ['func'] = t,
     ['nups'] = 0 -- i CANNOT make an upvalue thingy
     }
end

funcs.Drawing.Fonts = {
  ['UI'] = 0,
  ['System'] = 1,
  ['Plex'] = 2,
  ['Monospace'] = 3
}


local ClipboardQueue = Queue.new()
local ConsoleQueue = Queue.new()
local getgenv = getgenv or getfenv(2)
getgenv().getgenv = getgenv
-- _G fix:
getgenv()._G = table.clone(_G)

-- [[ Functions ]]

--[[funcs.cloneref = function(a)
    if not clonerefs[a] then clonerefs[a] = {} end
    local Clone = {}

    local mt = {__type='Instance'} -- idk if this works ;(

    mt.__tostring = function()
        return a.Name
    end

    mt.__index = function(_, key)
        local thing = a[key]
        if type(thing) == 'function' then
            return function(...)
                return thing(a, ...)
            end
        else
            return thing
        end
    end
    mt.__newindex = function(_, key, value)
     a[key] = value
    end
    mt.__metatable = 'The metatable is locked'
    mt.__len = function(self)
     return error('attempt to get length of a userdata value')
    end

    setmetatable(Clone, mt)

    table.insert(clonerefs[a], Clone)

    return Clone
end
 FUNCTION REMOVED FOR NOW.
]]
funcs.compareinstances = function(a, b)
 if not clonerefs[a] then
  return a == b
 else
  if table.find(clonerefs[a], b) then return true end
 end
 return false
end
funcs.cache.iscached = function(thing)
 return cache[thing] ~= 'REMOVE' and thing:IsDescendantOf(game) or false -- If it's cache isnt 'REMOVE' and its a des of game (Usually always true) or if its cache is 'REMOVE' then its false.
end
funcs.cache.invalidate = function(thing)
 cache[thing] = 'REMOVE'
 thing.Parent = nil
end
funcs.cache.replace = function(a, b)
 if cache[a] then
  cache[a] = b
 end
 local n, p = a.Name, a.Parent -- name, parent
 b.Parent = p
 b.Name = n
 a.Parent = nil
end
funcs.deepclone = function(a)
 local Result = {}
 for i, v in pairs(a) do
  if type(v) == 'table' then
    Result[i] = funcs.deepclone(v)
  end
  Result[i] = v
 end
 return Result
end

funcs.base64.encode = function(data)
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return letters:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
funcs.base64.decode = function(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0')
        end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2^(8 - i) or 0)
        end
        return string.char(c)
    end))
end

funcs.loadstring = function(code)
 local s1, val1 = pcall(function()
  return loadstring('local v1=15;v1+=1;return v1')()
 end)
 local s2, val2 = pcall(function()
  return loadstring('local v1={"a"};for i, v in v1 do return v end')()
 end)
 if val1 ~= 16 and val2 ~= 'a' then
  return oldLoader(toluau(code))
 else
  return oldLoader(code)
 end
end

funcs.getgenv = getgenv
funcs.crypt.base64 = funcs.base64
funcs.crypt.base64encode = funcs.base64.encode
funcs.crypt.base64decode = funcs.base64.decode
funcs.crypt.base64_encode = funcs.base64.encode
funcs.crypt.base64_decode = funcs.base64.decode
funcs.base64_encode = funcs.base64.encode
funcs.base64_decode = funcs.base64.decode

funcs.crypt.hex.encode = function(txt)
 txt = tostring(txt)
 local hex = ''
 for i = 1, #txt do
    hex = hex .. string.format("%02x", string.byte(txt, i))
 end
 return hex
end
funcs.crypt.hex.decode = function(hex)
    hex = tostring(hex)
    local text = ""
    for i = 1, #hex, 2 do
        local byte_str = string.sub(hex, i, i+1)
        local byte = tonumber(byte_str, 16)
        text = text .. string.char(byte)
    end
    return text
end
funcs.crypt.url.encode = function(a)
 return game:GetService("HttpService"):UrlEncode(a)
end
funcs.crypt.url.decode = function(a)
    a = tostring(a)
    a = string.gsub(a, "+", " ")
    a = string.gsub(a, "%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    a = string.gsub(a, "\r\n", "\n")
    return a
end
funcs.crypt.generatekey = function(optionalSize)
 local key = ''
 local a = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
 for i = 1, optionalSize or 32 do local n = math.random(1, #a) key = key .. a:sub(n, n) end
 return funcs.base64.encode(key)
end
funcs.crypt.generatebytes = function(size)
 if type(size) ~= 'number' then return error('missing arguement #1 to \'generatebytes\' (number expected)') end
 return funcs.crypt.generatekey(size)
end
funcs.crypt.encrypt = function(a, b)
 local result = {}
 a = tostring(a) b = tostring(b)
 for i = 1, #a do
    local byte = string.byte(a, i)
    local keyByte = string.byte(b, (i - 1) % #b + 1)
    table.insert(result, string.char(bit32.bxor(byte, keyByte)))
 end
 return table.concat(result)
end
funcs.crypt.decrypt = funcs.crypt.encrypt
funcs.crypt.random = function(len)
 return funcs.crypt.generatekey(len)
end

funcs.isrbxactive = function()
 return active
end
funcs.isgameactive = funcs.isrbxactive
funcs.gethui = function()
 local s, H = pcall(function()
  return game:GetService("CoreGui").RobloxGui
 end)
 if H then
  if not hui.Parent then
    hui.Parent = H.Parent
  end
  return hui
 else
  if not hui.Parent then
    hui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
  end
 end
 return hui
end
if getgenv().getrenv and #getgenv().getrenv() == 0 or not getgenv().getrenv then
 getgenv().getrenv = nil
 getgenv().getrenv = function() -- Override incognito's getrenv
  return renv -- couldn't think of a better way to implement it
 end
end

funcs.fireclickdetector = function(a1) --[[ this and firetouchinterest will be replaced, since they can be done using fireevent ]]
	assert(typeof(a1) == "Instance", "Instance expected")

    if a1:IsA("ClickDetector") then
        print("A1 is correct instance type")
    else
        print("A1 is the incorrect instance type!")
    end

    if a1.ClassName == "ClickDetector" then
        _ing1("fireclickdetector", game:GetService("Players").LocalPlayer, a1);
    else
        for _,v in pairs(a1:GetDescendants()) do
            if v.ClassName == "ClickDetector" then
                _ing1("fireclickdetector", game:GetService("Players").LocalPlayer, v);
            end
        end
    end

end

funcs.getgenv = function() 
    return getrawmetatable(getfenv(0)).__index
end
funcs.getsenv = function(scr)
    if scr == nil then 
        return getfenv()
    end
    for i, v in next, getreg() do
        if type(v) == "function" and getfenv(v).script == scr then
            return getfenv(v)
        end
    end
    error("Script environment could not be found.")
end
funcs.setclipboard = function(data)
    repeat task.wait() until ClipboardQueue:Current()[1] == data or ClipboardQueue:IsEmpty()
    ClipboardQueue:Queue(data)
    local old = game:GetService("UserInputService"):GetFocusedTextBox()
    local copy = ClipboardQueue:Current()[1]
    ClipboardBox:CaptureFocus()
    ClipboardBox.Text = copy
    
    local KeyCode = Enum.KeyCode
    local Keys = {KeyCode.RightControl, KeyCode.A}
    local Keys2 = {KeyCode.RightControl, KeyCode.C, KeyCode.V}
    
    for _, v in ipairs(Keys) do
        vim:SendKeyEvent(true, v, false, game)
        task.wait()
    end
    for _, v in ipairs(Keys) do
        vim:SendKeyEvent(false, v, false, game)
        task.wait()
    end
    for _, v in ipairs(Keys2) do
        vim:SendKeyEvent(true, v, false, game)
        task.wait()
    end
    for _, v in ipairs(Keys2) do
        vim:SendKeyEvent(false, v, false, game)
        task.wait()
    end
    ClipboardBox.Text = ''
    if old then old:CaptureFocus() end
    task.wait(.18)
    ClipboardQueue:Update()
end
funcs.syn.write_clipboard = funcs.setclipboard
funcs.toclipboard = funcs.setclipboard
funcs.writeclipboard = funcs.setclipboard
funcs.setrbxclipboard = funcs.setclipboard

funcs.isrenderobj = function(thing)
 return Drawings[thing] ~= nil
end
funcs.getrenderproperty = function(thing, prop)
 return thing[prop]
end
funcs.setrenderproperty = function(thing, prop, val)
 local success, err = pcall(function()
  thing[prop] = val
 end)
 if not success and err then warn(err) end
end

funcs.syn.protect_gui = function(gui)
 names[gui] = {name=gui.Name,parent=gui.Parent}
 protecteduis[gui] = gui
 gui.Name = funcs.crypt.random(64) -- 64 byte string, removed hashing cuz its useless lmao
 gui.Parent = gethui()
end
funcs.syn.unprotect_gui = function(gui)
 if names[gui] then gui.Name = names[gui].name gui.Parent = names[gui].parent end protecteduis[gui] = nil
end
funcs.syn.protectgui = funcs.syn.protect_gui
funcs.syn.unprotectgui = funcs.syn.unprotect_gui
funcs.syn.secure_call = function(func) -- Does not do a secure call, just pcalls it.
 return pcall(func)
end


funcs.isreadonly = function(tbl)
 if type(tbl) ~= 'table' then return false end
 return table.isfrozen(tbl)
end
funcs.setreadonly = function(tbl, cond)
 if cond then
  table.freeze(tbl)
 else
  return funcs.deepclone(tbl)
 end
end
funcs.httpget = function(url)
 return game:HttpGet(url)
end
funcs.httppost = function(url, body, contenttype)
 return game:HttpPostAsync(url, body, contenttype)
end
funcs.request = function(args)
 local Body = nil
 local Timeout = 0
 local function callback(success, body)
  Body = body
  Body['Success'] = success
 end
 HttpService:RequestInternal(args):Start(callback)
 while not Body and Timeout < 10 do
  task.wait(.1)
  Timeout = Timeout + .1
 end
 return Body
end
funcs.mouse1click = function(x, y)
 x = x or 0
 y = y or 0
 vim:SendMouseButtonEvent(x, y, 0, true, game, false)
 task.wait()
 vim:SendMouseButtonEvent(x, y, 0, false, game, false)
end
funcs.mouse2click = function(x, y)
 x = x or 0
 y = y or 0
 vim:SendMouseButtonEvent(x, y, 1, true, game, false)
 task.wait()
 vim:SendMouseButtonEvent(x, y, 1, false, game, false)
end
funcs.mouse1press = function(x, y)
 x = x or 0
 y = y or 0
 vim:SendMouseButtonEvent(x, y, 0, true, game, false)
end
funcs.mouse1release = function(x, y)
 x = x or 0
 y = y or 0
 vim:SendMouseButtonEvent(x, y, 0, false, game, false)
end
funcs.mouse2press = function(x, y)
 x = x or 0
 y = y or 0
 vim:SendMouseButtonEvent(x, y, 1, true, game, false)
end
funcs.mouse2release = function(x, y)
 x = x or 0
 y = y or 0
 vim:SendMouseButtonEvent(x, y, 1, false, game, false)
end
funcs.mousescroll = function(x, y, a)
 x = x or 0
 y = y or 0
 a = a and true or false
 vim:SendMouseWheelEvent(x, y, a, game)
end
funcs.keyclick = function(key)
 if typeof(key) == 'number' then
 if not keys[key] then return error("Key "..tostring(key) .. ' not found!') end
 vim:SendKeyEvent(true, keys[key], false, game)
 task.wait()
 vim:SendKeyEvent(false, keys[key], false, game)
 elseif typeof(Key) == 'EnumItem' then
  vim:SendKeyEvent(true, key, false, game)
  task.wait()
  vim:SendKeyEvent(false, key, false, game)
 end
end
funcs.keypress = function(key)
 if typeof(key) == 'number' then
 if not keys[key] then return error("Key "..tostring(key) .. ' not found!') end
 vim:SendKeyEvent(true, keys[key], false, game)
 elseif typeof(Key) == 'EnumItem' then
  vim:SendKeyEvent(true, key, false, game)
 end
end
funcs.keyrelease = function(key)
 if typeof(key) == 'number' then
 if not keys[key] then return error("Key "..tostring(key) .. ' not found!') end
 vim:SendKeyEvent(false, keys[key], false, game)
 elseif typeof(Key) == 'EnumItem' then
  vim:SendKeyEvent(false, key, false, game)
 end
end
funcs.mousemoverel = function(relx, rely)
 local Pos = workspace.CurrentCamera.ViewportSize
 relx = relx or 0
 rely = rely or 0
 local x = Pos.X * relx
 local y = Pos.Y * rely
 vim:SendMouseMoveEvent(x, y, game)
end
funcs.mousemoveabs = function(x, y)
 x = x or 0 y = y or 0
 vim:SendMouseMoveEvent(x, y, game)
end

funcs.newcclosure = function(f)
 local a = coroutine.wrap(function(...)
  local b = {coroutine.yield()}
  while true do
   b = {coroutine.yield(f(table.unpack(b)))}
  end
 end)
 a()
 return a
end -- Credits to myworld AND EMPER for this
funcs.iscclosure = function(fnc) return debug.info(fnc, 's') == '[C]' end
funcs.islclosure = function(func) return not funcs.iscclosure(func) end
funcs.isexecutorclosure = function(fnc)
    local found = false
    for i, v in pairs(getgenv()) do
     if v == fnc then return true end
    end
    for i = 1, math.huge do
        local s, env = pcall(getfenv, i)
        if not s or found then break end
        if type(env) == "table" then
            for _, v in pairs(env) do
                if v == fnc then
                    found = true
                    break
                end
            end
        end
        if found then break end
    end

    return found
end
funcs.newlclosure = function(fnc)
 return function(...) return fnc(...) end
end
funcs.clonefunction = funcs.newlclosure
funcs.is_l_closure = funcs.islclosure
funcs.is_executor_closure = funcs.isexecutorclosure
funcs.isourclosure = funcs.isexecutorclosure
funcs.isexecclosure = funcs.isexecutorclosure
funcs.checkclosure = funcs.isourclosure

funcs.http.request = funcs.request
funcs.syn.crypt = funcs.crypt
funcs.syn.crypto = funcs.crypt
funcs.syn_backup = funcs.syn


funcs.getexecutorname = function()
 return 'server_0', Version
end
funcs.identifyexecutor = funcs.getexecutorname
funcs.http_request = getgenv().request or funcs.request
funcs.getscripts = function()
 local a = {};for i, v in pairs(game:GetDescendants()) do if v:IsA("LocalScript") or v:IsA("ModuleScript") then table.insert(a, v) end end return a
end
funcs.get_scripts = function()
 local a = {};for i, v in pairs(game:GetDescendants()) do if v:IsA("LocalScript") or v:IsA("ModuleScript") then table.insert(a, v) end end return a
end
funcs.getmodules = function()
 local a = {};for i, v in pairs(game:GetDescendants()) do if v:IsA("ModuleScript") then table.insert(a, v) end end return a
end

funcs.isfile = function(a1)
     assert(type(a1) == "string", "String file path expected") 
     return _ing1("isfile", a1) 
end

funcs.appendfile = function(a1, a2) 
    assert(type(a1) == "string", "String file path expected") _ing1("appendfile", a1, a2) 
end

funcs.getloadedmodules = funcs.getmodules
funcs.make_readonly = funcs.setreadonly
funcs.makereadonly = funcs.setreadonly
funcs.base64encode = funcs.crypt.base64encode
funcs.base64decode = funcs.crypt.base64decode
funcs.clonefunc = funcs.clonefunction
funcs.setsimulationradius = function(Distance, MaxDistance)
 local LocalPlayer = game:GetService("Players").LocalPlayer
 assert(type(Distance)=='number','Invalid arguement #1 to \'setsimulationradius\', Number expected got ' .. type(Distance))
 LocalPlayer.SimulationRadius = type(Distance) == 'number' and Distance or LocalPlayer.SimulationRadius
 if MaxDistance then
  assert(type(MaxDistance)=='number','Invalid arguement #2 to \'setsimulationradius\', Number expected got ' .. type(MaxDistance))
  LocalPlayer.MaxSimulationDistance = MaxDistance
 end
end
funcs.getinstances = function()
 return game:GetDescendants()
end
funcs.getnilinstances = function()
 return Instances
end
funcs.iswriteable = function(tbl)
 return not table.isfrozen(tbl)
end
funcs.makewriteable = function(tbl)
 return funcs.setreadonly(tbl, false)
end
funcs.isscriptable = function(self, prop)
 return table.find(Hidden, prop) == nil
end
funcs.getrunningscripts = function()
 local scripts = {}
 for _, v in pairs(funcs.getinstances()) do
  if v:IsA("LocalScript") and v.Enabled then table.insert(scripts, v) end
 end
 return scripts
end
funcs.fireproximityprompt = function(p)
 local Hold, Distance, Enabled, Thing, CFrame1= p.HoldDuration, p.MaxActivationDistance, p.Enabled, p.RequiresLineOfSight, nil
 -- Make it activatable from anywhere
 p.MaxActivationDistance = math.huge
 -- Make it take 0 seconds to activate
 p.HoldDuration = 0
 -- Make it enabled (so you can activate it)
 p.Enabled = true
 -- Disable RequiresLineOfSight
 p.RequiresLineOfSight = false
 -- Show the thingy
 local function get()
  local classes = {'BasePart', 'Part', 'MeshPart'}
  for _, v in pairs(classes) do
   if p:FindFirstAncestorOfClass(v) then
    return p:FindFirstAncestorOfClass(v)
   end
  end
 end
 local a = get()
 if not a then
  local parent = p.Parent
  p.Parent = Instance.new("Part", workspace)
  a = p.Parent
 end
 CFrame1 = a.CFrame
 a.CFrame = game:GetService("Players").LocalPlayer.Character.Head.CFrame + game:GetService("Players").LocalPlayer.Character.Head.CFrame.LookVector * 2
 task.wait()
 p:InputHoldBegin()
 task.wait()
 p:InputHoldEnd()
 p.HoldDuration = Hold
 p.MaxActivationDistance = Distance
 p.Enabled = Enabled
 p.RequiresLineOfSight = Thing
 a.CFrame = CFrame1
 p.Parent = parent or p.Parent
end
funcs.firetouchinterest = function(toTouch, TouchWith, on)
 if on == 0 then return end
 if toTouch.ClassName == 'TouchTransmitter' then
   local function get()
    local classes = {'BasePart', 'Part', 'MeshPart'}
    for _, v in pairs(classes) do
    if toTouch:FindFirstAncestorOfClass(v) then
     return toTouch:FindFirstAncestorOfClass(v)
    end
   end
  end
  toTouch = get()
 end
 local cf = toTouch.CFrame
 local anc = toTouch.CanCollide
 toTouch.CanCollide = false
 toTouch.CFrame = TouchWith.CFrame
 task.wait()
 toTouch.CFrame = cf
 toTouch.CanCollide = anc
end -- i admit its kinda bad dont fucking attack me

-- SHA256 Hashing
local function str2hexa(a)return string.gsub(a,".",function(b)return string.format("%02x",string.byte(b))end)end;local function num2s(c,d)local a=""for e=1,d do local f=c%256;a=string.char(f)..a;c=(c-f)/256 end;return a end;local function s232num(a,e)local d=0;for g=e,e+3 do d=d*256+string.byte(a,g)end;return d end;local function preproc(h,i)local j=64-(i+9)%64;i=num2s(8*i,8)h=h.."\128"..string.rep("\0",j)..i;assert(#h%64==0)return h end;local function k(h,e,l)local m={}local n={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}for g=1,16 do m[g]=s232num(h,e+(g-1)*4)end;for g=17,64 do local o=m[g-15]local p=bit.bxor(bit.rrotate(o,7),bit.rrotate(o,18),bit.rshift(o,3))o=m[g-2]local q=bit.bxor(bit.rrotate(o,17),bit.rrotate(o,19),bit.rshift(o,10))m[g]=(m[g-16]+p+m[g-7]+q)%2^32 end;local r,s,b,t,u,v,w,x=l[1],l[2],l[3],l[4],l[5],l[6],l[7],l[8]for e=1,64 do local p=bit.bxor(bit.rrotate(r,2),bit.rrotate(r,13),bit.rrotate(r,22))local y=bit.bxor(bit.band(r,s),bit.band(r,b),bit.band(s,b))local z=(p+y)%2^32;local q=bit.bxor(bit.rrotate(u,6),bit.rrotate(u,11),bit.rrotate(u,25))local A=bit.bxor(bit.band(u,v),bit.band(bit.bnot(u),w))local B=(x+q+A+n[e]+m[e])%2^32;x=w;w=v;v=u;u=(t+B)%2^32;t=b;b=s;s=r;r=(B+z)%2^32 end;l[1]=(l[1]+r)%2^32;l[2]=(l[2]+s)%2^32;l[3]=(l[3]+b)%2^32;l[4]=(l[4]+t)%2^32;l[5]=(l[5]+u)%2^32;l[6]=(l[6]+v)%2^32;l[7]=(l[7]+w)%2^32;l[8]=(l[8]+x)%2^32 end;funcs.crypt.hash=function(h)h=preproc(h,#h)local l={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}for e=1,#h,64 do k(h,e,l)end;return str2hexa(num2s(l[1],4)..num2s(l[2],4)..num2s(l[3],4)..num2s(l[4],4)..num2s(l[5],4)..num2s(l[6],4)..num2s(l[7],4)..num2s(l[8],4))end

funcs.Drawing.new = function(Type) -- Drawing.new
    local baseProps = {
     Visible = false,
     Color = Color3.new(0,0,0),
     ClassName = nil
    }
    if Type == 'Line' then
        local a = Instance.new("Frame", Instance.new("ScreenGui", DrawingDict))
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Thickness = 1,
            From = Vector2.new(0, 0),
            To = Vector2.new(0, 0),
            Transparency = 0,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateLine = function(self)
             if not a then return end
             local from = self.From
             local to = self.To
             local distance = (to - from).Magnitude
             local angle = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))

             a.Size = UDim2.new(0, distance, 0, self.Thickness)
             a.Position = UDim2.new(0, from.X, 0, from.Y)
             a.Rotation = angle
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Thickness' and typeof(value) == 'number' then
                rawset(self, key, value)
                a.Size = UDim2.new(0, (self.To - self.From).Magnitude, 0, value)
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
                a.BackgroundColor3 = value
            elseif key == 'Transparency' and typeof(value) == 'number' and value <= 1 then
                rawset(self, key, value)
                a.BackgroundTransparency = 1 - value
            elseif key == 'From' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateLine()
            elseif key == 'To' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateLine()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Square' then
        local a = Instance.new("Frame", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        local b = Instance.new("UIStroke", a)
        b.Color = Color3.fromRGB(255, 255, 255)
        b.Enabled = true

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Size = Vector2.new(0,0),
            Position = Vector2.new(0, 0),
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateSquare = function(self)
             if not a then return end
             a.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Filled' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                b.Enabled = not value
                a.BackgroundTransparency = value and 0 or 1
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
                a.BackgroundColor3 = value
                b.Color = value
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateSquare()
            elseif key == 'Size' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateSquare()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Circle' then
        local a = Instance.new("Frame", Instance.new("ScreenGui", DrawingDict))
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        local b = Instance.new("UIStroke", a)
        b.Color = Color3.fromRGB(255, 255, 255)
        b.Enabled = false
        b.Thickness = 1
        local c = Instance.new("UICorner", a)
        c.CornerRadius = UDim.new(1, 0)

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Thickness = 1,
            Filled = false,
            NumSides = 0,
            Radius = 1,
            Position = Vector2.new(0, 0),
            Transparency = 0,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateCircle = function(self)
             if not b or not a then return end
             a.Size = UDim2.new(0, self.Radius, 0, self.Radius)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             b.Enabled = not self
             b.Color = self.Color
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Thickness' and typeof(value) == 'number' then
                rawset(self, key, value)
                b.Thickness = value
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
                a.BackgroundColor3 = value
                a.Color = value
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
                a.BackgroundTransparency = 1 - value
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateCircle()
            elseif key == 'Radius' and typeof(value) == 'number' then
                rawset(self, key, value)
                self:updateCircle()
            elseif key == 'NumSides' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Filled' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                self:updateCircle()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Text' then
        local a = Instance.new("TextLabel", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        a.TextStrokeColor3 = Color3.new(0,0,0)
        a.TextStrokeTransparency = 1

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Text = '',
            Transparency = 0,
            Size = 0,
            Center = false,
            Outline = false,
            OutlineColor = Color3.new(0,0,0),
            Position = Vector2.new(0,0),
            Font = 3,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateText = function(self)
             if not a then return end
             a.TextScaled = true
             a.Size = UDim2.new(0, self.Size * 3, 0, self.Size / 2)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             a.Text = self.Text
             a.Font = Fonts[self.Font]
             a.Visible = self.Visible
             a.TextColor3 = self.Color
             a.TextTransparency = 1 - self.Transparency
             a.BorderSizePixel = self.Outline and 1 or 0
             if self.Center then
              a.TextXAlignment = Enum.TextXAlignment.Center
              a.TextYAlignment = Enum.TextYAlignment.Center
             else
              a.TextXAlignment = Enum.TextXAlignment.Left
              a.TextYAlignment = Enum.TextYAlignment.Top
             end
             a.TextStrokeTransparency = self.Outline and 0 or 1
             a.TextStrokeColor3 = self.OutlineColor
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Text' and typeof(value) == 'string' then
                rawset(self, key, value)
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
            elseif key == 'Size' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Outline' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'Center' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'OutlineColor' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Font' and typeof(value) == 'number' then
                rawset(self, key, value)
            end
            self:updateText()
        end

        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Image' then
        local a = Instance.new("ImageLabel", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.ImageColor3 = Color3.fromRGB(255,255,255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0

        local meta = baseProps
        meta.ClassName = 'Image'
        meta.__index = {
            Text = '',
            Transparency = 0,
            Size = Vector2.new(0, 0),
            Position = Vector2.new(0,0),
            Color = Color3.fromRGB(255, 255, 255),
            Image = '',
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy()
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do
                if v == meta then Drawings[i] = nil end
               end
               a:Destroy()
            end,
            updateImage = function(self)
             if not a then return end
             a.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             a.Visible = self.Visible
             a.ImageColor3 = self.Color
             a.ImageTransparency = 1 - self.Transparency
             a.BorderSizePixel = self.Outline and 1 or 0
             a.Image = self.Image
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'Color' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
            elseif key == 'Size' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Image' and typeof(value) == 'string' then
                rawset(self, key, value)
            else
             return
            end
            self:updateImage()
        end

        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    end
end

funcs.randomstring = funcs.crypt.random
funcs.getprotecteduis = function()
 return protecteduis
end
funcs.getprotectedguis = funcs.getprotecteduis
funcs.cleardrawcache = function()
 for _, v in pairs(Drawings) do
  v:Remove()
 end
 table.clear(Drawings)
end
funcs.checkcaller = function()
 local info = debug.info(getgenv, 'slnaf')
 return debug.info(1, 'slnaf')==info
end
funcs.getthreadcontext = function() -- funny little way of getting this
 if coroutine.isyieldable(coroutine.running()) then -- check if u can use task.wait or not
  QueueGetIdentity()
  task.wait(.1)
  return tonumber(Identity)
 else
  if Identity == -1 then
   task.spawn(QueueGetIdentity)
   return 1
  else
   return tonumber(Identity)
  end
  return tonumber(Identity)
 end
end
funcs.getthreadidentity = funcs.getthreadcontext
funcs.getidentity = funcs.getthreadcontext
funcs.rconsolecreate = function()
    local Clone = Console:Clone()
    Clone.Parent = gethui()
    ConsoleClone = Clone
    ConsoleClone.ConsoleFrame.Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(input, ConsoleClone.ConsoleFrame)
        end
    end)
end
funcs.rconsoledestroy = function()
    if ConsoleClone then ConsoleClone:Destroy() end
    ConsoleClone = nil
end
funcs.rconsoleprint = function(msg, cc)
    local CONSOLE = ConsoleClone or Console
	repeat task.wait() until ConsoleQueue:IsEmpty()
	msg = tostring(msg)
	local last_color = nil

	msg = msg:gsub('@@(%a+)@@', function(color)
		local colorName = color:upper()
		local rgbColor = colors[colorName]
		if rgbColor then
			local fontTag = string.format('<font color="rgb(%d,%d,%d)">', rgbColor.R * 255, rgbColor.G * 255, rgbColor.B * 255)
			local result = last_color and '</font>' .. fontTag or fontTag
			last_color = colorName
			return result
		else
			return '@@' .. color .. '@@'
		end
	end)

	if last_color then
		msg = msg .. '</font>'
	end
	
	if msg:match('<font color=".+">.+</font>') then
	 if msg:match('<font color=".+"></font>') == msg then MessageColor = colors[last_color] return end
	end
	
	local tmp = MessageTemplate:Clone()
	tmp.Parent = CONSOLE.ConsoleFrame.Holder
	tmp.Text = msg
	tmp.Visible = true
	tmp.TextColor3 = cc and cc or MessageColor
end
funcs.rconsoleinput = function()
    local CONSOLE = ConsoleClone or Console
    repeat task.wait() until ConsoleQueue:IsEmpty()
    ConsoleQueue:Queue('input')
    local box = InputTemplate:Clone()
    local val
    box.Parent = CONSOLE.ConsoleFrame.Holder
    box.Visible = true
    box.TextEditable = true
    box.TextColor3 = MessageColor

    box.FocusLost:Connect(function(a)
     if not a then return end
     val = box.Text
     ConsoleQueue:Update()
    end)

    local FOCUSED = false
    while true do
     if box.Text:sub(#box.Text, #box.Text) == '_' or box.Text == '' or not box:IsFocused() then
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Text = box.Text .. '_'
        
        for _ = 1, 100 do
            task.wait(1/2)
            if box:IsFocused() then
                FOCUSED = true
                box.TextColor3 = MessageColor
                break
            end
            box.Text = box.Text:sub(#box.Text, #box.Text) == '_' and box.Text:sub(#box.Text-1, #box.Text-1) or box.Text .. '_'
        end
        if FOCUSED then break end
     else
        task.wait(0.1)
     end
    end
    repeat task.wait() until val
    return val
end
funcs.rconsolename = function(a)
 if ConsoleClone then
  ConsoleClone.ConsoleFrame.Title.Text = a
 else
  Console.ConsoleFrame.Title.Text = a
 end
end
funcs.printconsole = function(msg, r, g, b)
 r = r or 0
 g = g or 0
 b = b or 0
 rconsoleprint(msg, Color3.fromRGB(r, g, b))
end
funcs.rconsoleclear = function()
 if ConsoleClone then
 for i, v in pairs(ConsoleClone.ConsoleFrame.Holder:GetChildren()) do
  if v.ClassName == 'TextLabel' or v.ClassName == 'TextBox' then v:Destroy() end
 end
 else
  for i, v in pairs(Console.ConsoleFrame.Holder:GetChildren()) do
   if v.ClassName == 'TextLabel' or v.ClassName == 'TextBox' then v:Destroy() end
  end
 end
end
funcs.rconsoleinfo = function(a)
 rconsoleprint('[INFO]: ' .. tostring(a))
end
funcs.rconsolewarn = function(a)
 rconsoleprint('[*]: ' .. tostring(a))
end
funcs.rconsoleerr = function(a)
 local clr = MessageColor
 local oldColor
 for i, v in pairs(colors) do
  if clr == v then oldColor = i break end
 end
 rconsoleprint(string.format('[@@RED@@*@@%s@@]: %s', oldColor, tostring(a)))
end
funcs.rconsoleinputasync = funcs.rconsoleinput
funcs.consolecreate = funcs.rconsolecreate
funcs.consoleclear = funcs.rconsoleclear
funcs.consoledestroy = funcs.rconsoledestroy
funcs.consoleinput = funcs.rconsoleinput
funcs.rconsolesettitle = funcs.rconsolename
funcs.consolesettitle = funcs.rconsolename

funcs.queue_on_teleport = function(scripttoexec) -- WARNING: MUST HAVE MOREUNC IN AUTO EXECUTE FOR THIS TO WORK.
 local newTPService = {
  __index = function(self, key)
   if key == 'Teleport' then
    return function(gameId, player, teleportData, loadScreen)
      teleportData = {teleportData, MOREUNCSCRIPTQUEUE=scripttoexec}
      return oldGame:GetService("TeleportService"):Teleport(gameId, player, teleportData, loadScreen)
    end
   end
  end
 }
 local gameMeta = {
  __index = function(self, key)
    if key == 'GetService' then
     return function(name)
      if name == 'TeleportService' then return newTPService end
     end
    elseif key == 'TeleportService' then return newTPService end
    return game[key]
  end,
  __metatable = 'The metatable is protected'
 }
 getgenv().game = setmetatable({}, gameMeta)
end
funcs.queueonteleport = funcs.queue_on_teleport

local funcs2 = {}
for i, _ in pairs(funcs) do
 table.insert(funcs2, i)
end

for _, i in pairs(funcs2) do
 SafeOverride(i, funcs[i])
end

syn.protect_gui(DrawingDict)
syn.protect_gui(ClipboardUI)
QueueGetIdentity()

function readfile(path)
    local content = httpget("http://localhost:5000/readfile?path=" .. path:gsub("/", "\\"))
    print(content)
    return content
end

function writefile(path, text)
    local response = httpget("http://localhost:5000/writefile?path=" .. path:gsub("/", "\\") .. "&text=" .. text)
    print(response)
    return response
end

function makefolder(name)
    local response = httpget("http://localhost:5000/makefolder?name=" .. name:gsub("/", "\\"))
    print(response)
    return response
end

function listfiles(path)
    local response = httpget("http://localhost:5000/listfiles?path=" .. path:gsub("/", "\\"))
    print(response)
    local files_table = game:GetService("HttpService"):JSONDecode(response)
    print(files_table)
    for i, v in pairs(files_table) do
        print(i, v)
    end    
    return files_table
end

function delfile(path)
    local basepath = "path to workspace folder here"
    local response = httpget("http://localhost:5000/delfile?path=" .. basepath..path:gsub("/", "\\"))
    return response
end

function delfolder(path)
    local basepath = "path to workspace folder here"
    local construct = basepath..path:gsub("/", "\\")
    local response = httpget("http://localhost:5000/delfolder?path="..construct)
    return response
end

getrenv = function() 
    return _ing1("getrenv")
 end
