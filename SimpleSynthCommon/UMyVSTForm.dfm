object FormMyVST: TFormMyVST
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'FormMyVST'
  ClientHeight = 338
  ClientWidth = 651
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  Scaled = False
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 32
    Top = 48
    Width = 34
    Height = 16
    Caption = 'Cutoff'
  end
  object Label2: TLabel
    Left = 32
    Top = 176
    Width = 37
    Height = 16
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 32
    Top = 80
    Width = 62
    Height = 16
    Caption = 'Resonance'
  end
  object Label4: TLabel
    Left = 32
    Top = 112
    Width = 67
    Height = 16
    Caption = 'Pulse Width'
  end
  object Label5: TLabel
    Left = 32
    Top = 8
    Width = 47
    Height = 16
    Caption = 'MyVST3'
  end
  object ScrollBar1: TScrollBar
    Left = 136
    Top = 48
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 0
    OnChange = ScrollBar1Change
  end
  object ScrollBar2: TScrollBar
    Left = 136
    Top = 80
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 1
    OnChange = ScrollBar1Change
  end
  object ScrollBar3: TScrollBar
    Left = 136
    Top = 112
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 2
    OnChange = ScrollBar1Change
  end
  object Button1: TButton
    Left = 160
    Top = 167
    Width = 75
    Height = 25
    Caption = 'Set Prgm 1'
    TabOrder = 3
    OnClick = Button1Click
  end
end
