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
  OldCreateOrder = False
  Scaled = False
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 32
    Top = 48
    Width = 43
    Height = 16
    Caption = 'Volume'
  end
  object Label2: TLabel
    Left = 32
    Top = 88
    Width = 37
    Height = 16
    Caption = 'Label2'
  end
  object ScrollBar1: TScrollBar
    Left = 104
    Top = 48
    Width = 265
    Height = 21
    PageSize = 0
    TabOrder = 0
    OnChange = ScrollBar1Change
  end
end
