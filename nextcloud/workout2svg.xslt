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
		xmlns:xlink="http://www.w3.org/1999/xlink"
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

	<!-- parameters -->
	<param name="mapboxStyle">mapbox/outdoors-v11</param>
	<param name="mapboxToken" />

	<!-- config -->
	<variable name="offsetX" as="xs:integer">40</variable>
	<variable name="offsetY" as="xs:integer">15</variable>
	<variable name="mapHeight" as="xs:integer">490</variable>
	<variable name="graphHeight" as="xs:integer">100</variable>
	<variable name="height" as="xs:integer" select="$mapHeight + $graphHeight + 10" />
	<variable name="width" as="xs:integer">600</variable>
	<variable name="lineStep" as="xs:integer"><value-of select="round($graphHeight div 4)" /></variable>
	<variable name="colorAltitude">grey</variable>
	<variable name="colorHeart">#e74c3c</variable>
	<variable name="colorMeta">white</variable>
	<variable name="colorSpeed">#3498db</variable>
	<!-- <variable name="colorCadence">#8e44ad</variable> -->
	<variable name="colorCadence">none</variable>
	<variable name="fontSizeChart">7pt</variable>
	<variable name="fontSizeMeta">11pt</variable>
	<variable name="fontOffsetY">9pt</variable>
	<attribute-set name="fontStyle">
		<attribute name="dy">9pt</attribute>
		<attribute name="font-family">sans-serif</attribute>
		<attribute name="font-size">9pt</attribute>
		<attribute name="font-stretch">condensed</attribute>
	</attribute-set>

	<template match="/tcd:TrainingCenterDatabase/tcd:Activities/tcd:Activity|/gpx:gpx/gpx:trk|/gpx/trk">
		<variable name="times" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Time|gpx:trkseg/gpx:trkpt/gpx:time|trkseg/trkpt/time" as="xs:dateTime*" />
		<variable name="meters">
			<choose>
				<when test="tcd:Lap/tcd:DistanceMeters">
					<value-of select="sum(tcd:Lap/tcd:DistanceMeters)" />
				</when>
				<when test="gpx:trkseg/gpx:trkpt|trkseg/trkpt">
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
					<value-of select="sum(exslt:node-set($distance)/*)" />
				</when>
			</choose>
		</variable>

		<element name="svg" namespace="http://www.w3.org/2000/svg">
			<attribute name="height">
				<value-of select="$height" />
			</attribute>
			<attribute name="viewBox">
				<text>0 0 </text>
				<value-of select="$width" />
				<text> </text>
				<value-of select="$height" />
			</attribute>
			<attribute name="width" select="$width" />

			<!-- gradients -->
			<element name="defs" namespace="http://www.w3.org/2000/svg">

				<!-- gray out -->
				<element name="linearGradient" namespace="http://www.w3.org/2000/svg">
					<attribute name="id">grayOut</attribute>
					<attribute name="x1">0</attribute>
					<attribute name="x2">0</attribute>
					<attribute name="y1">0</attribute>
					<attribute name="y2">1</attribute>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">0%</attribute>
						<attribute name="stop-color">black</attribute>
						<attribute name="stop-opacity">0.5</attribute>
					</element>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">100%</attribute>
						<attribute name="stop-color">black</attribute>
						<attribute name="stop-opacity">0</attribute>
					</element>
				</element>

				<!-- white out -->
				<element name="linearGradient" namespace="http://www.w3.org/2000/svg">
					<attribute name="id">whiteOut</attribute>
					<attribute name="x1">0</attribute>
					<attribute name="x2">0</attribute>
					<attribute name="y1">0</attribute>
					<attribute name="y2">1</attribute>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">0%</attribute>
						<attribute name="stop-color">white</attribute>
						<attribute name="stop-opacity">1</attribute>
					</element>
					<element name="stop" namespace="http://www.w3.org/2000/svg">
						<attribute name="offset">100%</attribute>
						<attribute name="stop-color">white</attribute>
						<attribute name="stop-opacity">0</attribute>
					</element>
				</element>

				<!-- heart gradient -->
				<element name="linearGradient" namespace="http://www.w3.org/2000/svg">
					<variable name="rates" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:HeartRateBpm/tcd:Value|gpx:trkseg/gpx:trkpt/gpx:extensions/tpe:TrackPointExtension/tpe:hr|trkseg/trkpt/extensions/TrackPointExtension/hr" />
					<variable name="minRate" select="min($rates)" />
					<variable name="maxRate" select="max($rates)" />

					<attribute name="id">heartGradient</attribute>
					<attribute name="gradientUnits">userSpaceOnUse</attribute>
					<attribute name="x1">0</attribute>
					<attribute name="x2">0</attribute>
					<attribute name="y1" select="0" />
					<attribute name="y2" select="185" />
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

			<!-- background -->
			<element name="rect" namespace="http://www.w3.org/2000/svg">
				<attribute name="fill">white</attribute>
				<attribute name="height" select="$height + $offsetY + $graphHeight" />
				<attribute name="width" select="$width" />
				<attribute name="x">0</attribute>
				<attribute name="y">0</attribute>
			</element>

			<!-- map -->
			<element name="g" namespace="http://www.w3.org/2000/svg">
				<variable name="lats" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Position/tcd:LatitudeDegrees|gpx:trkseg/gpx:trkpt/@lat|trkseg/trkpt/@lat" />
				<variable name="lons" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Position/tcd:LongitudeDegrees|gpx:trkseg/gpx:trkpt/@lon|trkseg/trkpt/@lon" />
				<variable name="minLat" select="min($lats)" />
				<variable name="maxLat" select="max($lats)" />
				<variable name="minLon" select="min($lons)" />
				<variable name="maxLon" select="max($lons)" />
				<variable name="centerLon" select="($minLon + $maxLon) div 2" />
				<variable name="centerLat" select="($minLat + $maxLat) div 2" />
				<!--<variable name="scaleX" select="$height div ($maxLon - $minLon)" />
				<variable name="scaleY" select="$width div ($maxLat - $minLat)" />
				<variable name="scale" select="min(($scaleX, $scaleY))" />-->
				<variable name="scale" select="9300" />
				<!-- km = 111.3 * ($maxLat - $minLat) -->

				<element name="image" namespace="http://www.w3.org/2000/svg">
					<variable name="url">
						<text>https://api.mapbox.com/styles/v1/</text>
						<value-of select="$mapboxStyle" />
						<text>/static/</text>
						<value-of select="$centerLon" />
						<text>,</text>
						<value-of select="$centerLat" />
						<text>,</text>
						<value-of select="12" />
						<text>,0/</text>
						<value-of select="$width" />
						<text>x</text>
						<value-of select="$mapHeight" />
						<text>@2x?access_token=</text>
						<value-of select="$mapboxToken" />
					</variable>
					<attribute name="height" select="$mapHeight" />
					<attribute name="href" select="$url" />
					<attribute name="width" select="$width" />
					<attribute name="x">0</attribute>
					<attribute name="xlink:href" select="$url" />
					<attribute name="y">0</attribute>
				</element>

				<element name="g" namespace="http://www.w3.org/2000/svg">
					<variable name="start" select="min($times)" />
					<variable name="end" select="max($times)" />
					<variable name="diff" select="$end - $start" />
					<variable name="seconds" select="$diff div xs:dayTimeDuration('PT1S')" />

					<attribute name="fill" select="$colorMeta" />
					<attribute name="font-family">sans-serif</attribute>
					<attribute name="font-size" select="$fontSizeMeta" />

					<!-- background -->
					<element name="rect" namespace="http://www.w3.org/2000/svg">
						<attribute name="height">80</attribute>
						<attribute name="width" select="$width" />
						<attribute name="x">0</attribute>
						<attribute name="y">0</attribute>
						<attribute name="fill">url(#grayOut)</attribute>
					</element>
					<element name="rect" namespace="http://www.w3.org/2000/svg">
						<attribute name="height">80</attribute>
						<attribute name="fill">url(#whiteOut)</attribute>
						<attribute name="transform">scale(1,-1)</attribute>
						<attribute name="width" select="$width" />
						<attribute name="x">0</attribute>
						<attribute name="y" select="-$mapHeight" />
					</element>

					<!-- distance -->
					<element name="text" namespace="http://www.w3.org/2000/svg">
						<attribute name="dy" select="$fontSizeMeta" />
						<attribute name="x" select="$offsetX" />
						<attribute name="y" select="20" />
						<text disable-output-escaping="yes"><![CDATA[&#x1F3C3;&#xFE0E; ]]></text>
						<value-of select="format-number($meters div 1000, '0.0')" />
						<text> km</text>
					</element>

					<!-- pace -->
					<element name="text" namespace="http://www.w3.org/2000/svg">
						<variable name="pace" select="($seconds div 60) div ($meters div 1000)" />
						<attribute name="dy" select="$fontSizeMeta" />
						<attribute name="text-anchor">middle</attribute>
						<attribute name="x" select="$width div 2" />
						<attribute name="y" select="20" />
						<text disable-output-escaping="yes"><![CDATA[&#x23F1;&#xFE0E; ]]></text>
						<value-of select="floor($pace)" />
						<text>:</text>
						<value-of select="format-number(($pace * 60) mod 60, '00')" />
						<text> min/km</text>
						<text> = </text>
						<value-of select="format-number(60 div $pace, '0.0')" />
						<text> km/h</text>
					</element>

					<!-- time -->
					<element name="text" namespace="http://www.w3.org/2000/svg">
						<attribute name="dy" select="$fontSizeMeta" />
						<attribute name="text-anchor">end</attribute>
						<attribute name="x" select="$width - $offsetX" />
						<attribute name="y" select="20" />
						<text disable-output-escaping="yes"><![CDATA[&#x1F3C1;&#xFE0E; ]]></text>
						<value-of select="hours-from-duration($diff)" />
						<text>:</text>
						<value-of select="format-number(minutes-from-duration($diff), '00')" />
						<text>:</text>
						<value-of select="format-number(seconds-from-duration($diff), '00')" />
					</element>

				</element>

				<!-- track -->
				<element name="polyline" namespace="http://www.w3.org/2000/svg">
					<attribute name="fill">none</attribute>
					<attribute name="stroke">red</attribute>
					<attribute name="stroke-width">2</attribute>
					<attribute name="points">
						<for-each select="1 to count($lats)">
							<variable name="pos" select="position()" />
							<value-of select="($lons[position() = $pos] - $centerLon) * $scale div 1.61" />
							<text>,</text>
							<value-of select="($lats[position() = $pos] - $centerLat) * -$scale" />
							<text> </text>
						</for-each>
					</attribute>
					<attribute name="transform">
						<text>translate(</text>
						<value-of select="$width div 2" />
						<text>,</text>
						<value-of select="$mapHeight div 2" />
						<text>) </text>
					</attribute>
				</element>

			</element>

			<!-- graphs -->
			<element name="g" namespace="http://www.w3.org/2000/svg">
				<attribute name="transform">
					<text>translate(0,</text>
					<value-of select="$height - $graphHeight - 10" />
					<text>)</text>
				</attribute>

				<!-- lines -->
				<element name="g" namespace="http://www.w3.org/2000/svg">
					<variable name="countLaps" select="$meters div 1000" />

					<attribute name="font-family">sans-serif</attribute>
					<attribute name="font-size" select="$fontSizeChart" />
					<attribute name="stroke">lightgrey</attribute>
						<attribute name="transform">
							<text>scale(</text>
							<value-of select="($width - 80) div $width" />
							<text>,1)</text>
						</attribute>

					<!-- x axis -->
					<for-each select="1 to xs:integer($countLaps)">
						<element name="line" namespace="http://www.w3.org/2000/svg">
							<attribute name="x1" select="$width div $countLaps * ." />
							<attribute name="x2" select="$width div $countLaps * ." />
							<attribute name="y1" select="$graphHeight - 5" />
							<attribute name="y2" select="$graphHeight" />
						</element>
						<element name="text" namespace="http://www.w3.org/2000/svg">
							<attribute name="dy" select="$fontSizeChart" />
							<attribute name="fill">lightgrey</attribute>
							<attribute name="stroke">none</attribute>
							<attribute name="text-anchor">middle</attribute>
							<attribute name="x" select="$width div $countLaps * (. - 0.5)" />
							<attribute name="y" select="$graphHeight" />
							<value-of select="." />
						</element>
					</for-each>

					<!-- y axis -->
					<for-each select="0 to 4">
						<element name="line" namespace="http://www.w3.org/2000/svg">
							<attribute name="x1">0</attribute>
							<attribute name="x2" select="$width" />
							<attribute name="y1" select="min(($graphHeight div 4 * ., $graphHeight - 0.5))" />
							<attribute name="y2" select="min(($graphHeight div 4 * ., $graphHeight - 0.5))" />
						</element>
					</for-each>

					<!-- altitude -->
					<call-template name="graph">
						<with-param name="color" select="$colorAltitude" />
						<with-param name="posLegend" select="$width + 30" />
						<with-param name="type">polygon</with-param>
						<with-param name="unit">m</with-param>
						<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:AltitudeMeters|gpx:trkseg/gpx:trkpt/gpx:ele|trkseg/trkpt/ele" />
					</call-template>

					<!-- speed -->
					<call-template name="graph">
						<with-param name="factor">3.6</with-param>
						<with-param name="color" select="$colorSpeed" />
						<with-param name="posLegend" select="$width + 60" />
						<with-param name="unit">km/h</with-param>
						<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Extensions/ae:TPX/ae:Speed|gpx:trkseg/gpx:trkpt/gpx:extensions/gpx:speed|trkseg/trkpt/extensions/speed" />
					</call-template>

					<!-- heart rate -->
					<call-template name="graph">
						<with-param name="color">url(#heartGradient)</with-param>
						<with-param name="posLegend" select="$width + 90" />
						<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:HeartRateBpm/tcd:Value|gpx:trkseg/gpx:trkpt/gpx:extensions/tpe:TrackPointExtension/tpe:hr|trkseg/trkpt/extensions/TrackPointExtension/hr" />
					</call-template>

					<!-- cadence -->
					<call-template name="graph">
						<with-param name="color" select="$colorCadence" />
						<with-param name="posLegend">45</with-param>
						<with-param name="values" select="tcd:Lap/tcd:Track/tcd:Trackpoint/tcd:Extensions/ae:TPX/ae:RunCadence|gpx:trkseg/gpx:trkpt/gpx:extensions/tpe:TrackPointExtension/tpe:cad|trkseg/trkpt/extensions/TrackPointExtension/cad" />
					</call-template>

				</element>

			</element>
		</element>
	</template>

	<template name="graph">
		<param name="color" />
		<param name="factor" select="1" />
		<param name="posLegend" select="$width" />
		<param name="type" select="'polyline'" />
		<param name="unit" />
		<param name="values" />

		<if test="$values">
			<element name="g" namespace="http://www.w3.org/2000/svg">
				<attribute name="fill" select="$color" />
				<choose>
					<when test="$posLegend &lt; $width div 2">
						<attribute name="text-anchor">start</attribute>
					</when>
					<otherwise>
						<attribute name="text-anchor">end</attribute>
					</otherwise>
				</choose>

				<!-- helpers -->
				<variable name="scaleX" select="$width div count($values)" />
				<variable name="minValue" select="min($values)" />
				<variable name="maxValue" select="max($values)" />
				<variable name="scaleY" select="$graphHeight div ($maxValue - $minValue)" />

				<!-- graph -->
				<element name="g" namespace="http://www.w3.org/2000/svg">
					<element name="{$type}" namespace="http://www.w3.org/2000/svg">
						<choose>
							<when test="$type = 'polygon'">
								<attribute name="opacity">.25</attribute>
								<attribute name="stroke">none</attribute>
							</when>
							<otherwise>
								<attribute name="fill">none</attribute>
								<attribute name="opacity">.6</attribute>
								<attribute name="stroke" select="$color" />
								<attribute name="stroke-width">1.5</attribute>
							</otherwise>
						</choose>
						<attribute name="points">
							<if test="$type = 'polygon'">
								<value-of select="count($values)" />
								<text>,</text>
								<value-of select="$minValue" />
								<text> </text>
								<value-of select="1" />
								<text>,</text>
								<value-of select="$minValue" />
								<text> </text>
							</if>
							<for-each select="$values">
								<value-of select="position() * $scaleX" />
								<text>,</text>
								<value-of select="(. - $maxValue) * -$scaleY" />
								<text> </text>
							</for-each>
						</attribute>
					</element>
				</element>

				<!-- legend -->
				<element name="text" namespace="http://www.w3.org/2000/svg">
					<attribute name="dy" select="$fontSizeChart" />
					<attribute name="stroke">none</attribute>
					<attribute name="text-anchor">end</attribute>
					<attribute name="x" select="$posLegend" />
					<attribute name="y" select="$graphHeight" />
					<value-of select="$unit" />
				</element>
				<for-each select="0 to 4">
					<element name="text" namespace="http://www.w3.org/2000/svg">
						<variable name="value" select="(($maxValue - $minValue) div 4 * (4 - .) + $minValue) * $factor" />
						<attribute name="stroke">none</attribute>
						<attribute name="text-anchor">end</attribute>
						<attribute name="x" select="$posLegend" />
						<attribute name="y" select=". * $lineStep" />
						<choose>
							<when test="$maxValue &gt; 50">
								<value-of select="round($value)" />
							</when>
							<otherwise>
								<value-of select="format-number($value, '0.#')" />
							</otherwise>
						</choose>
					</element>
				</for-each>

			</element>
		</if>
	</template>

	<!-- ignore text nodes -->
	<template match="text()" />

</stylesheet>
