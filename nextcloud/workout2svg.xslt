<?xml version="1.0"?>

<stylesheet version="2.0"
		xmlns="http://www.w3.org/1999/XSL/Transform"
		xmlns:ae="http://www.garmin.com/xmlschemas/ActivityExtension/v2"
		xmlns:exslt="http://exslt.org/common"
		xmlns:fn="http://www.w3.org/2005/xpath-functions"
		xmlns:gpx="http://www.topografix.com/GPX/1/1"
		xmlns:math="http://www.w3.org/2005/xpath-functions/math"
		xmlns:tcd="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
		xmlns:tpe="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		>
	<output
		doctype-public="-//W3C//DTD SVG 1.1//EN"
		doctype-system="http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
		indent="yes"
		media-type="image/svg"
		method="xml"
		standalone="no"
		/>

	<!-- config -->
	<variable name="offsetX" as="xs:integer">40</variable>
	<variable name="offsetY" as="xs:integer">15</variable>
	<variable name="height" as="xs:integer">500</variable>
	<variable name="width" as="xs:integer">1000</variable>
	<variable name="lineStep" as="xs:integer">75</variable>
	<variable name="colorLaps">#aaaaaa</variable>
	<variable name="colorAltitude">#52be80</variable>
	<variable name="colorHeart">#e74c3c</variable>
	<variable name="colorSpeed">#3498db</variable>
	<variable name="colorTimes">grey</variable>
	<!-- <variable name="colorCadence">#8e44ad</variable> -->
	<variable name="colorCadence">none</variable>
	<variable name="fontOffsetY">9pt</variable>
	<attribute-set name="fontStyle">
		<attribute name="dy">9pt</attribute>
		<attribute name="font-family">sans-serif</attribute>
		<attribute name="font-size">9pt</attribute>
		<attribute name="font-stretch">condensed</attribute>
		<attribute name="font-weight">bold</attribute>
	</attribute-set>

	<template name="document">
		<param name="times" />

		<element name="svg" namespace="http://www.w3.org/2000/svg" use-attribute-sets="fontStyle">
			<attribute name="viewBox">
				<text>0 0 </text>
				<value-of select="$width" />
				<text> </text>
				<value-of select="$height" />
			</attribute>
			<attribute name="width">
				<value-of select="$width" />
			</attribute>

			<element name="clipPath" namespace="http://www.w3.org/2000/svg">
				<attribute name="id">clipGraph</attribute>
				<element name="polygon" namespace="http://www.w3.org/2000/svg">
					<attribute name="points">
						<value-of select="$offsetX" />
						<text>,</text>
						<value-of select="0" />
						<text> </text>
						<value-of select="$width - $offsetX" />
						<text>,</text>
						<value-of select="0" />
						<text> </text>
						<value-of select="$width - $offsetX" />
						<text>,</text>
						<value-of select="$height - $offsetY" />
						<text> </text>
						<value-of select="$offsetX" />
						<text>,</text>
						<value-of select="$height - $offsetY" />
					</attribute>
				</element>
			</element>

			<element name="polygon" namespace="http://www.w3.org/2000/svg">
				<attribute name="fill">white</attribute>
				<attribute name="points">
					<text>0,0 </text>
					<value-of select="$width" />
					<text>,</text>
					<value-of select="0" />
					<text> </text>
					<value-of select="$width" />
					<text>,</text>
					<value-of select="$height" />
					<text> </text>
					<value-of select="0" />
					<text>,</text>
					<value-of select="$height" />
				</attribute>
			</element>

			<apply-templates />

			<!-- lines -->
			<element name="g" namespace="http://www.w3.org/2000/svg">
				<attribute name="stroke">
					<value-of select="$colorTimes" />
				</attribute>

				<for-each select="1 to xs:integer(($height - $offsetY) div $lineStep)">
					<element name="line" namespace="http://www.w3.org/2000/svg">
						<attribute name="x1">
							<value-of select="$offsetX" />
						</attribute>
						<attribute name="x2">
							<value-of select="$width - $offsetX" />
						</attribute>
						<attribute name="y1">
							<value-of select=". * $lineStep" />
						</attribute>
						<attribute name="y2">
							<value-of select=". * $lineStep" />
						</attribute>
					</element>
				</for-each>
			</element>

			<!-- times -->
			<element name="g" namespace="http://www.w3.org/2000/svg">
				<attribute name="fill">
					<value-of select="$colorTimes" />
				</attribute>
				<attribute name="text-anchor">middle</attribute>

				<for-each select="$times">
					<if test="position() = 1">

						<!-- date -->
						<element name="text" namespace="http://www.w3.org/2000/svg">
							<attribute name="dy">
								<value-of select="$fontOffsetY" />
							</attribute>
							<attribute name="x">
								<value-of select="$offsetX" />
							</attribute>
							<attribute name="y">
								<value-of select="$height - $offsetY" />
							</attribute>
							<value-of select="substring(., 12, 8)" />
						</element>

						<!-- start time -->
						<element name="text" namespace="http://www.w3.org/2000/svg">
							<attribute name="dy">
								<value-of select="$fontOffsetY" />
							</attribute>
							<attribute name="x">
								<value-of select="$width div 2" />
							</attribute>
							<attribute name="y">
								<value-of select="$height - $offsetY" />
							</attribute>
							<value-of select="substring(., 0, 11)" />
						</element>

					</if>

					<if test="position() = last()">

						<!-- end time -->
						<element name="text" namespace="http://www.w3.org/2000/svg">
							<attribute name="dy">
								<value-of select="$fontOffsetY" />
							</attribute>
							<attribute name="x">
								<value-of select="$width - $offsetX" />
							</attribute>
							<attribute name="y">
								<value-of select="$height - $offsetY" />
							</attribute>
							<value-of select="substring(., 12, 8)" />
						</element>

					</if>
				</for-each>
			</element>
		</element>
	</template>

	<template name="graph">
		<param name="color" />
		<param name="factor" select="1" />
		<param name="posLegend" select="0" />
		<param name="type" select="'polyline'" />
		<param name="unit" />
		<param name="values" />

		<if test="$values">
			<element name="g" namespace="http://www.w3.org/2000/svg">
				<attribute name="fill">
					<value-of select="$color" />
				</attribute>
				<choose>
					<when test="$posLegend &lt; $width div 2">
						<attribute name="text-anchor">start</attribute>
					</when>
					<otherwise>
						<attribute name="text-anchor">end</attribute>
					</otherwise>
				</choose>

				<!-- helpers -->
				<variable name="scaleX" select="($width - $offsetX * 2) div count($values)" />
				<variable name="minValue" select="min($values)" />
				<variable name="maxValue" select="max($values)" />
				<variable name="scaleY" select="($height - $offsetY) div ($maxValue - $minValue)" />

				<!-- graph -->
				<element name="{$type}" namespace="http://www.w3.org/2000/svg">
					<choose>
						<when test="$type = 'polygon'">
							<attribute name="opacity">.25</attribute>
						</when>
						<otherwise>
							<attribute name="fill">none</attribute>
							<attribute name="opacity">.6</attribute>
							<attribute name="stroke">
								<value-of select="$color" />
							</attribute>
							<attribute name="stroke-width">
								<value-of select="2" />
							</attribute>
						</otherwise>
					</choose>
					<attribute name="points">
						<if test="$type = 'polygon'">
							<value-of select="$width - $offsetX" />
							<text>,</text>
							<value-of select="$height - $offsetY" />
							<text> </text>
							<value-of select="$offsetX" />
							<text>,</text>
							<value-of select="$height - $offsetY" />
							<text> </text>
						</if>
						<for-each select="$values">
							<value-of select="format-number($offsetX + position() * $scaleX, '0.0')" />
							<text>,</text>
							<value-of select="format-number((. - $minValue) * $scaleY * -1 + $height - $offsetY, '0.0')" />
							<text> </text>
						</for-each>
					</attribute>
				</element>

				<!-- legend -->
				<for-each select="0 to xs:integer(($height - $offsetY) div $lineStep)">
					<element name="text" namespace="http://www.w3.org/2000/svg">
						<variable name="value" select="((. * $lineStep - $height + $offsetY) div $scaleY div -1 + $minValue) * $factor" />
						<attribute name="dy">
							<value-of select="$fontOffsetY" />
						</attribute>
						<attribute name="x">
							<value-of select="$posLegend" />
						</attribute>
						<attribute name="y">
							<value-of select=". * $lineStep" />
						</attribute>
						<choose>
							<when test="$maxValue &gt; 50">
								<value-of select="round($value)" />
							</when>
							<otherwise>
								<value-of select="format-number($value, '0.#')" />
							</otherwise>
						</choose>
						<if test="$unit">
							<text> </text>
							<value-of select="$unit" />
						</if>
					</element>
				</for-each>

			</element>
		</if>
	</template>

	<!-- laps -->
	<template name="laps">
		<param name="meters" />
		<variable name="countLaps" select="$meters div 1000" />

		<element name="g" namespace="http://www.w3.org/2000/svg">
			<attribute name="clip-path">url(#clipGraph)</attribute>
			<attribute name="fill">
				<value-of select="$colorLaps" />
			</attribute>
			<attribute name="text-anchor">middle</attribute>

			<for-each select="1 to xs:integer(ceiling($meters div 1000))">
				<if test="position() mod 2 = 0">
					<element name="polygon" namespace="http://www.w3.org/2000/svg">
						<attribute name="opacity">.2</attribute>
						<attribute name="points">
							<value-of select="format-number((position() - 1) div $countLaps * ($width - $offsetX * 2) + $offsetX, '0.0')" />
							<text>,</text>
							<value-of select="0" />
							<text> </text>
							<value-of select="format-number(position() div $countLaps * ($width - $offsetX * 2) + $offsetX, '0.0')" />
							<text>,</text>
							<value-of select="0" />
							<text> </text>
							<value-of select="format-number(position() div $countLaps * ($width - $offsetX * 2) + $offsetX, '0.0')" />
							<text>,</text>
							<value-of select="$height - $offsetY" />
							<text> </text>
							<value-of select="format-number((position() - 1) div $countLaps * ($width - $offsetX * 2) + $offsetX, '0.0')" />
							<text>,</text>
							<value-of select="$height - $offsetY" />
						</attribute>
					</element>
				</if>
				<element name="text" namespace="http://www.w3.org/2000/svg">
					<attribute name="dy">
						<value-of select="$fontOffsetY" />
					</attribute>
					<attribute name="x">
						<value-of select="format-number((position() - .5) div $countLaps * ($width - $offsetX * 2) + $offsetX, '0.0')" />
					</attribute>
					<attribute name="y">
						<value-of select="$height - $offsetY * 2" />
					</attribute>
					<value-of select="position()" />
				</element>
			</for-each>
		</element>
	</template>

	<!-- heart rate color -->
	<template name="heartColor">
		<param name="values" />

		<if test="$values">
			<variable name="minValue">
				<for-each select="$values">
					<sort select="." data-type="number" order="ascending" />
					<if test="position() = 1">
						<value-of select="." />
					</if>
				</for-each>
			</variable>
			<variable name="maxValue" select="max($values)" />
			<variable name="scaleY" select="($height - $offsetY) div ($maxValue - $minValue)" />

			<element name="defs" namespace="http://www.w3.org/2000/svg">
				<element name="linearGradient" namespace="http://www.w3.org/2000/svg">
					<attribute name="id">heartGradient</attribute>
					<attribute name="gradientUnits">userSpaceOnUse</attribute>
					<attribute name="x1">0</attribute>
					<attribute name="x2">0</attribute>
					<attribute name="y1">
						<value-of select="(0 - $minValue) * $scaleY * -1 + $height - $offsetY" />
					</attribute>
					<attribute name="y2">
						<value-of select="(185 - $minValue) * $scaleY * -1 + $height - $offsetY" />
					</attribute>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">80%</attribute>
						<attribute name="stop-color">#27ae60</attribute>
					</element>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">80%</attribute>
						<attribute name="stop-color">#f1c40f</attribute>
					</element>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">90%</attribute>
						<attribute name="stop-color">#f1c40f</attribute>
					</element>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">90%</attribute>
						<attribute name="stop-color">#e74c3c</attribute>
					</element>
				</element>
			</element>
		</if>
	</template>


	<!-- tcx document -->
	<template match="/tcd:TrainingCenterDatabase">
		<call-template name="document">
			<with-param name="times" select="tcd:Activities/tcd:Activity/tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Time" />
		</call-template>
	</template>
	<template match="/tcd:TrainingCenterDatabase/tcd:Activities/tcd:Activity">

		<!-- heart gradient -->
		<call-template name="heartColor">
			<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:HeartRateBpm/tcd:Value" />
		</call-template>

		<!-- laps -->
		<call-template name="laps">
			<with-param name="meters" select="sum(tcd:Lap/tcd:DistanceMeters)" />
		</call-template>

		<!-- altitude -->
		<call-template name="graph">
			<with-param name="color">
				<value-of select="$colorAltitude" />
			</with-param>
			<with-param name="type">polygon</with-param>
			<with-param name="unit">m</with-param>
			<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:AltitudeMeters" />
		</call-template>

		<!-- speed -->
		<call-template name="graph">
			<with-param name="factor">3.6</with-param>
			<with-param name="color">
				<value-of select="$colorSpeed" />
			</with-param>
			<with-param name="posLegend">
				<value-of select="$width" />
			</with-param>
			<with-param name="unit">km/h</with-param>
			<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Extensions/ae:TPX/ae:Speed" />
		</call-template>

		<!-- heart rate -->
		<call-template name="graph">
			<with-param name="color">url(#heartGradient)</with-param>
			<with-param name="posLegend">
				<value-of select="$width - 60" />
			</with-param>
			<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:HeartRateBpm/tcd:Value" />
		</call-template>

		<!-- cadence -->
		<call-template name="graph">
			<with-param name="color">
				<value-of select="$colorCadence" />
			</with-param>
			<with-param name="posLegend">45</with-param>
			<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Extensions/ae:TPX/ae:RunCadence" />
		</call-template>

	</template>
	<template match="/tcd:TrainingCenterDatabase/tcd:Author"/>

	<!-- gpx document -->
	<template match="/gpx:gpx|/gpx">
		<call-template name="document">
			<with-param name="times" select="gpx:trk/gpx:trkseg/gpx:trkpt/gpx:time|trk/trkseg/trkpt/time" />
		</call-template>
	</template>
	<template match="/gpx:gpx/gpx:trk|/gpx/trk">
	
		<!-- laps -->
		<variable name="distance">
			<variable name="pi180" select="math:pi() div 180" />
			<variable name="r" select="6372.797 * 1000" />
			<for-each select="gpx:trkseg/gpx:trkpt|trkseg/trkpt">
				<if test="position() > 1" xmlns:dummy="#">
					<variable name="lat1" select="(preceding-sibling::gpx:trkpt[1]/@lat | preceding-sibling::trkpt[1]/@lat) * $pi180" />
					<variable name="lon1" select="(preceding-sibling::gpx:trkpt[1]/@lon | preceding-sibling::trkpt[1]/@lon) * $pi180" />
					<variable name="lat2" select="@lat * $pi180" />
					<variable name="lon2" select="@lon * $pi180" />
					<variable name="dlat" select="($lat2 - $lat1)" />
					<variable name="dlon" select="($lon2 - $lon1)" />
					<variable name="a" select="math:pow(math:sin($dlat div 2), 2) + math:cos($lat1) * math:cos($lat2) * math:pow(math:sin($dlon div 2), 2)" />
					<variable name="c" select="2 * math:atan2(math:sqrt($a), math:sqrt(1 - $a))" />
					<dummy:dummy>
						<value-of select="$r * $c" />
					</dummy:dummy>
				</if>
			</for-each>
		</variable>
		<call-template name="laps">
			<with-param name="meters" select="sum(exslt:node-set($distance)/*)" />
		</call-template>

		<!-- heart gradient -->
		<call-template name="heartColor">
			<with-param name="values" select="gpx:trkseg/gpx:trkpt/gpx:extensions/tpe:TrackPointExtension/tpe:hr|trkseg/trkpt/extensions/TrackPointExtension/hr" />
		</call-template>

		<!-- altitude -->
		<call-template name="graph">
			<with-param name="color">
				<value-of select="$colorAltitude" />
			</with-param>
			<with-param name="type">polygon</with-param>
			<with-param name="unit">m</with-param>
			<with-param name="values" select="gpx:trkseg/gpx:trkpt/gpx:ele|trkseg/trkpt/ele" />
		</call-template>

		<!-- speed -->
		<call-template name="graph">
			<with-param name="color">
				<value-of select="$colorSpeed" />
			</with-param>
			<with-param name="factor">3.6</with-param>
			<with-param name="posLegend">
				<value-of select="$width" />
			</with-param>
			<with-param name="unit">km/h</with-param>
			<with-param name="values" select="gpx:trkseg/gpx:trkpt/gpx:extensions/gpx:speed|trkseg/trkpt/extensions/speed" />
		</call-template>

		<!-- heart rate -->
		<call-template name="graph">
			<with-param name="color">url(#heartGradient)</with-param>
			<with-param name="posLegend">
				<value-of select="$width - 60" />
			</with-param>
			<with-param name="values" select="gpx:trkseg/gpx:trkpt/gpx:extensions/tpe:TrackPointExtension/tpe:hr|trkseg/trkpt/extensions/TrackPointExtension/hr" />
		</call-template>

		<!-- cadence -->
		<call-template name="graph">
			<with-param name="color">
				<value-of select="$colorCadence" />
			</with-param>
			<with-param name="posLegend">45</with-param>
			<with-param name="values" select="gpx:trkseg/gpx:trkpt/gpx:extensions/tpe:TrackPointExtension/tpe:cad|trkseg/trkpt/extensions/TrackPointExtension/cad" />
		</call-template>

	</template>

	<!-- ignore text nodes -->
	<template match="text()" />

</stylesheet>
