import QtQuick

// CPU and RAM as two stacked gauges, sized like the usaKi gauges.
Cell {
    label: "<font color='" + Theme.topaz + "'>CPU " + Math.round(Cpu.usage * 100) + "</font> · <font color='" + Theme.peridot + "'>RAM " + Math.round(Cpu.ram * 100) + "</font>"
    icon: "cpu"
    iconColor: Theme.topaz
    labelColor: Theme.faint
    Item {
        width: 70
        height: 11
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Gauge { width: 70; height: 4; value: Cpu.usage; endColor: Theme.topaz }
            Gauge { width: 70; height: 5; value: Cpu.ram; endColor: Theme.peridot }
        }
    }
}
