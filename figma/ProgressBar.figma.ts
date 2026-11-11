// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=143-3602
// source=Sources/VigilDesignSystem/Components/ProgressBar.swift
// component=ProgressBar
import figma from 'figma'
const instance = figma.selectedInstance

const value = instance.getEnum('Value', {
  '0%': '0.0',
  '10%': '0.1',
  '20%': '0.2',
  '30%': '0.3',
  '40%': '0.4',
  '50%': '0.5',
  '60%': '0.6',
  '70%': '0.7',
  '80%': '0.8',
  '90%': '0.9',
  '100%': '1.0',
})

export default {
  example: figma.code`ProgressBar(value: ${value})`,
  imports: ['import VigilDesignSystem'],
  id: 'progress-bar',
  metadata: { nestable: true, props: { value } },
}
