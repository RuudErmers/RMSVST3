object FormAthenaVST: TFormAthenaVST
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'FormAthenaVST'
  ClientHeight = 700
  ClientWidth = 1100
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
    Left = 48
    Top = 400
    Width = 34
    Height = 16
    Caption = 'Cutoff'
  end
  object Label2: TLabel
    Left = 48
    Top = 528
    Width = 37
    Height = 16
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 48
    Top = 432
    Width = 62
    Height = 16
    Caption = 'Resonance'
  end
  object Label4: TLabel
    Left = 48
    Top = 464
    Width = 67
    Height = 16
    Caption = 'Pulse Width'
  end
  object Label5: TLabel
    Left = 8
    Top = 112
    Width = 377
    Height = 16
    Caption = 'Athena for VST3 - Roadmap: Suggest Music Thoery Scales'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Fkeyboard: TRMCKeyboard
    Left = 0
    Top = 0
    Width = 1100
    Height = 106
    Octaves = 5
    Align = alTop
    ExplicitLeft = 64
    ExplicitTop = 96
    ExplicitWidth = 665
  end
  object Label6: TLabel
    Left = 480
    Top = 676
    Width = 595
    Height = 16
    Caption = 
      'VST'#174' is a trademark of Steinberg Media Technologies GmbH, regist' +
      'ered in Europe and other countries.'
  end
  object ScrollBar1: TScrollBar
    Left = 152
    Top = 400
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 0
    OnChange = ScrollBar1Change
  end
  object ScrollBar2: TScrollBar
    Left = 152
    Top = 432
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 1
    OnChange = ScrollBar1Change
  end
  object ScrollBar3: TScrollBar
    Left = 152
    Top = 464
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 2
    OnChange = ScrollBar1Change
  end
  object Button1: TButton
    Left = 176
    Top = 519
    Width = 75
    Height = 25
    Caption = 'Set Prgm 1'
    TabOrder = 3
    OnClick = Button1Click
  end
end
