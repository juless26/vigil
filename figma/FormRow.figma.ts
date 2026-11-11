// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2885
// source=Sources/VigilDesignSystem/Components/FormRow.swift
// component=FormTextRow, FormPickerRow
import figma from 'figma'
const instance = figma.selectedInstance

const type = instance.getEnum('Type', {
  'Text': 'text',
  'Picker': 'picker',
})
const label = instance.getString('Label')
const value = instance.getString('Value')

let example
if (type === 'picker') {
  example = figma.code`FormPickerRow(
    label: "${label}",
    options: options,
    selection: $selection,
    title: { $0.title }
) // currently "${value}"`
} else {
  example = figma.code`FormTextRow(label: "${label}", prompt: "${value}", text: $text)`
}

export default {
  example,
  imports: ['import VigilDesignSystem'],
  id: 'form-row',
  metadata: { nestable: true },
}
