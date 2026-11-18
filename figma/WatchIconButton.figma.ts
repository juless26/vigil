// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=201-2880
// source=Sources/VigilDesignSystem/Components/Watch/WatchIconButton.swift
// component=WatchIconButton
import figma from 'figma'
const instance = figma.selectedInstance

const icon = instance.getEnum('Icon', {
  'Pause': '.pause',
})

export default {
  example: figma.code`WatchIconButton(${icon}, label: "Pause for nurse") { }`,
  imports: ['import VigilDesignSystem'],
  id: 'watch-icon-button',
  metadata: { nestable: true },
}
