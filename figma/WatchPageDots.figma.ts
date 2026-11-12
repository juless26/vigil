// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=163-4490
// source=Sources/VigilDesignSystem/Components/Watch/WatchPageDots.swift
// component=WatchPageDots
import figma from 'figma'
const instance = figma.selectedInstance

const page = instance.getEnum('Page', {
  '1': '.first',
  '2': '.second',
})

export default {
  example: figma.code`WatchPageDots(page: ${page})`,
  imports: ['import VigilDesignSystem'],
  id: 'watch-page-dots',
  metadata: { nestable: true },
}
