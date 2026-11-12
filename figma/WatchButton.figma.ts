// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=163-4480
// source=Sources/VigilDesignSystem/Components/Watch/WatchButton.swift
// component=WatchButton
import figma from 'figma'
const instance = figma.selectedInstance

const label = instance.getString('Label')

export default {
  example: figma.code`WatchButton("${label}") { }`,
  imports: ['import VigilDesignSystem'],
  id: 'watch-button',
  metadata: { nestable: true },
}
