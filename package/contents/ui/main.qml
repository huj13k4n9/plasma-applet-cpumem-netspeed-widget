/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.2
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    property bool showSeparately: plasmoid.configuration.showSeparately
    property bool showCPUAndMem: plasmoid.configuration.showCPUAndMem
    property string speedLayout: plasmoid.configuration.speedLayout
    property bool swapDownUp: plasmoid.configuration.swapDownUp
    property bool showIcons: plasmoid.configuration.showIcons
    property bool showUnits: plasmoid.configuration.showUnits
    property string speedUnits: plasmoid.configuration.speedUnits
    property bool shortUnits: plasmoid.configuration.shortUnits
    property double fontSizeScale: plasmoid.configuration.fontSize / 100
    property double updateInterval: plasmoid.configuration.updateInterval
    property bool customColors: plasmoid.configuration.customColors
    property color byteColor: plasmoid.configuration.byteColor
    property color kilobyteColor: plasmoid.configuration.kilobyteColor
    property color megabyteColor: plasmoid.configuration.megabyteColor
    property color gigabyteColor: plasmoid.configuration.gigabyteColor

    property bool launchApplicationEnabled: plasmoid.configuration.launchApplicationEnabled
    property string launchApplication: plasmoid.configuration.launchApplication
    property bool interfacesWhitelistEnabled: plasmoid.configuration.interfacesWhitelistEnabled
    property var interfacesWhitelist: plasmoid.configuration.interfacesWhitelist

    property var speedData: []
    property var cpuLoad: .0
    property var memTotal: 1
    property var memUsed: 0

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.compactRepresentation: CompactRepresentation {}

    Component.onCompleted: {
        // trigger adding all sources already available
        for (var i in dataSource.sources) {
            dataSource.sourceAdded(dataSource.sources[i]);
        }
    }

    PlasmaCore.DataSource {
        id: dataSource
        engine: 'systemmonitor'
        interval: updateInterval * 1000

        onSourceAdded: {
            if (source.indexOf('network/interfaces/lo/') !== -1) {
                return;
            }

            var matchNetwork = source.match(/^network\/interfaces\/(\w+)\/(receiver|transmitter)\/data(Total)?$/)

            var matchCPU = source.match(/^cpu\/system\/TotalLoad$/)
            var matchMem = source.match(/^mem\/physical\/(used|total)$/)

            if (matchNetwork) {
                connectSource(source)
                if (speedData[matchNetwork[1]] === undefined) {
                    console.log('Network interface added: ' + matchNetwork[1])
                }
            }

            if (matchCPU) {
                connectSource(source)
                console.log('CPU data initiated')
            }

            if (matchMem) {
                connectSource(source)
                if (matchMem[1] === 'used') {
                    console.log('MemUsed data initiated')
                } else if (matchMem[1] === 'total') {
                    console.log('MemTotal data initiated')
                } 
            }
        }

        onSourceRemoved: {
            var matchNetwork = source.match(/^network\/interfaces\/(\w+)\/(receiver|transmitter)\/data(Total)?$/)

            var matchCPU = source.match(/^cpu\/system\/TotalLoad$/)
            var matchMem = source.match(/^mem\/physical\/(used|total)$/)

            if (matchNetwork) {
                disconnectSource(source);
                if (speedData[matchNetwork[1]] !== undefined) {
                    delete speedData[matchNetwork[1]]
                    console.log('Network interface removed: ' + source[1])
                }
            }

            if (matchCPU || matchMem) {
                disconnectSource(source)
            }
        }

        onNewData: {
            if (data.value === undefined) {
                return
            }

            var matchNetwork = sourceName.match(/^network\/interfaces\/(\w+)\/(receiver|transmitter)\/data(Total)?$/)
            var matchCPU = sourceName.match(/^cpu\/system\/TotalLoad$/)
            var matchMem = sourceName.match(/^mem\/physical\/(used|total)$/)

            if (matchNetwork) {
                if (speedData[matchNetwork[1]] === undefined) {
                    speedData[matchNetwork[1]] = {down: 0, up: 0, downTotal: 0, upTotal: 0}
                }

                var d = speedData
                var changed = false
                var value = parseFloat(data.value)

                if (matchNetwork[3] === 'Total') {
                    if (matchNetwork[2] === 'receiver'    && d[matchNetwork[1]].downTotal != value) {
                        d[matchNetwork[1]].downTotal = value
                        changed = true
                    }
                    if (matchNetwork[2] === 'transmitter' && d[matchNetwork[1]].upTotal != value) {
                        d[matchNetwork[1]].upTotal = value
                        changed = true
                    }
                } else {
                    if (matchNetwork[2] === 'receiver'    && d[matchNetwork[1]].down != value) {
                        d[matchNetwork[1]].down = value
                        changed = true
                    }
                    if (matchNetwork[2] === 'transmitter' && d[matchNetwork[1]].up != value) {
                        d[matchNetwork[1]].up = value
                        changed = true
                    }
                }

                if (changed) {
                    speedData = d
                }
            } else if (matchCPU) {
                cpuLoad = parseFloat(data.value)
            } else if (matchMem) {
                if (matchMem[1] === 'used') {
                    memUsed = parseFloat(data.value)
                } else if (matchMem[1] === 'total') {
                    memTotal = parseFloat(data.value)
                } 
            }
        }
    }
}
