object SynthEditorForm: TSynthEditorForm
  Left = 289
  Top = 180
  BorderStyle = bsNone
  Caption = 'SynthEditorForm'
  ClientHeight = 78
  ClientWidth = 235
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 15
    Top = 50
    Width = 146
    Height = 20
    Caption = 'Internal Controller'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object ControllerBar: TTrackBar
    Left = 10
    Top = 10
    Width = 216
    Height = 26
    Hint = '|^b^aController'
    Max = 1000
    Orientation = trHorizontal
    PopupMenu = SynthResModule.ControlMenu
    Frequency = 50
    Position = 500
    SelEnd = 0
    SelStart = 0
    TabOrder = 0
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    OnChange = ControllerBarChange
  end
end
