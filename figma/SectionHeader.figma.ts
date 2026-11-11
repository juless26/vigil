// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2886
// source=Sources/VigilDesignSystem/Components/SectionHeader.swift
// component=SectionHeader
import figma from 'figma'
const instance = figma.selectedInstance

const title = instance.getString('Title')

export default {
  example: figma.code`SectionHeader("${title}")`,
  imports: ['import VigilDesignSystem'],
  id: 'section-header',
  metadata: { nestable: true },
}
