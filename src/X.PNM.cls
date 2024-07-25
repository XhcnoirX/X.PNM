/// Library to create PNM (Portable Anymap) images, of sub-formats PBM (Portable Bitmap), PGM (Portable Graymap), and PPM (Portable Pixmap).
Class X.PNM Extends %RegisteredObject
{

Property Type As %String(VALUELIST = ",P1,P2,P3,P4,P5,P6") [ Private ];

Property Width As %Integer [ InitialExpression = 0 ];

Property Height As %Integer [ InitialExpression = 0 ];

Property MaxVal As %Integer [ InitialExpression = 0 ];

Property Data As %DynamicArray [ Private ];

Method %OnNew(format As %String = "PPM", plain As %Boolean = 0, maxval As %Integer = 255, width As %Integer = 10, height As %Integer = 10) As %Status
{
	if '..SetFormat(format, plain, maxval) quit 0
	if '..SetSize(width, height) quit 0
	set ..Width = width
	set ..Height = height
	set ..Data = []
	quit 1
}

Method SetFormat(format As %String = "PPM", plain As %Boolean = 0, maxval As %Integer = 255) As %Boolean
{
	set format = $zconvert(format, "U")
	if format="PPM" {
		set ..Type = $case(plain,0:"P6",:"P3")
		if maxval>255 set maxval = 255
		set ..MaxVal = maxval
		quit 1
	}
	elseif format="PGM" {
		set ..Type = $case(plain,0:"P5",:"P2")
		if maxval>255 set maxval = 255
		set ..MaxVal = maxval
		quit 1
	}
	elseif format="PBM" {
		set ..Type = $case(plain,0:"P4",:"P1")
		set ..MaxVal = 1
		quit 1
	}
	do ..Error("Format " _ format _ " not supported!")
	quit 0
}

Method SetSize(width As %Integer = 10, height As %Integer = 10) As %Status
{
	if (width<=0) || (height<=0) quit 0
	set ..Width = width
	set ..Height = height
	quit 1
}

Method AddLine(pixels As %DynamicArray)
{
	if pixels.%Size()'=..Width {
		do ..Error("Line length is not " _ ..Width _ "!")
	}
	set iter = pixels.%GetIterator()
	while iter.%GetNext(.key, .pixel) {
		do ..Data.%Push(pixel)
	}
}

/// color2 and color3 only supported for PPM (P3/P6)
/// In which case color1, color2, color3 represent the Red, Green and Blue parts of the pixel color respectively
Method AddPixel(color1 As %Integer, color2 As %Integer, color3 As %Integer)
{
	set pixel = []
	do pixel.%Push(color1)
	if (..Type="P3") || (..Type="P6") {
		do pixel.%Push(color2)
		do pixel.%Push(color3)
	}
	do ..Data.%Push(pixel)
}

/// color2 and color3 only supported for PPM (P3/P6)
/// In which case color1, color2, color3 represent the Red, Green and Blue parts of the pixel color respectively
Method AddPixelAt(x As %Integer, y As %Integer, color1 As %Integer, color2 As %Integer, color3 As %Integer)
{
	set pixel = []
	do pixel.%Push(color1)
	if (..Type="P3") || (..Type="P6") {
		do pixel.%Push(color2)
		do pixel.%Push(color3)
	}
	do ..Data.%Set(y*..Width + x, pixel)
}

Method Save(file As %String) As %Status
{
	// make sure Data size (= pixel count) is correct
	if ..Data.%Size()'=(..Width * ..Height) {
		do ..Error("Invalid pixel size: " _ ..Data.%Size() _ ", should be " _ (..Width * ..Height) _ "!")
	}
	if ##class(%File).Exists(file) {
		do ..Error("File already exists!")
	}
	set stream = ##class(%Stream.FileCharacter).%New()
	set status = stream.LinkToFile(file)
	do stream.Rewind()
	do stream.WriteLine(..Type)
	do stream.WriteLine(..Width _ " " _..Height)
	if (..Type'="P1") && (..Type'="P4") do stream.Write(..MaxVal)
	if +$E(..Type, 2)<4 {
		do ..SavePlain(.stream)
	}
	else {
		// For PBM, a conversion from bits to bytes is needed
		//if ..Type="P4" do ..ConvertToBytes()
		do ..SaveBinary(.stream)
	}
	do stream.WriteLine("")
	do stream.%Save()
	do stream.%Close()
	quit $$$OK
}

Method SavePlain(ByRef stream)
{
	do stream.WriteLine()
	set pos = 0
	set line = ""
	set Iter = ..Data.%GetIterator()
	while Iter.%GetNext(.pos, .pixel) {
		if $l(line)>=59 {
			do stream.WriteLine(line)
			set line = ""
		}
		if (..Type="P3") || (..Type="P6") {
			set line = line _ pixel.%Get(0) _ " " _ pixel.%Get(1) _ " " _ pixel.%Get(2) _ " "
		}
		else {
			set line = line _ pixel.%Get(0) _ " "
		}
	}
	if $l(line) do stream.WriteLine(line)
	quit
}

Method SaveBinary(ByRef stream)
{
	set pos = 0
	set Iter = ..Data.%GetIterator()
	while Iter.%GetNext(.pos, .pixel) {
		if (..Type="P3") || (..Type="P6") {
			do stream.Write($char(pixel.%Get(0)) _ $char(pixel.%Get(1)) _ $char(pixel.%Get(2)))
		}
		else {
			do stream.Write($char(pixel.%Get(0)))
		}
	}
	quit
}

Method ConvertToBytes()
{
	set Temp = []
	set byte = 0
	set mult = 256
	set Iter = ..Data.%GetIterator()
	while Iter.%GetNext(.pos, .pixel) {
		set byte = byte + mult*pixel.%Get(0)
		if mult=1 {
			do Temp.%Push(byte)
			set mult = 256
			set byte = 0
		}
		else {
			set mult = mult/2
		}
	}
	do Temp.%Push(byte)
	set ..Data = Temp
}

Method Error(error As %String)
{
	set $zerror = error
	throw
}

}
