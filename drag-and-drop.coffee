###
Copyright (C) 2011 Jacob Beard
Released under GNU LGPL, read the file 'COPYING' and 'COPYING.LESSER' for more information
###

svgDrag = do ->

	svgNS = "http://www.w3.org/2000/svg"

	translate = (element,dx,dy) ->
		tl = element.transform.baseVal
		t = if tl.numberOfItems then tl.getItem(0) else element.ownerSVGElement.createSVGTransform()
		m = t.matrix
		newM = element.ownerSVGElement.createSVGMatrix().translate(dx,dy).multiply(m)
		t.setMatrix(newM)
		tl.initialize(t)

	getBoundingBoxInArbitrarySpace = (element,mat) ->
		svgRoot = element.ownerSVGElement
		bbox = element.getBBox()

		xs = []
		ys = []

		calc = ->
			cPtTr = cPt.matrixTransform(mat)
			xs.push cPtTr.x
			ys.push cPtTr.y

		cPt =  svgRoot.createSVGPoint()
		cPt.x = bbox.x
		cPt.y = bbox.y
		calc()
			
		cPt.x += bbox.width
		calc()

		cPt.y += bbox.height
		calc()

		cPt.x -= bbox.width
		calc()
		
		minX=Math.min.apply this,xs
		minY=Math.min.apply this,ys
		maxX=Math.max.apply this,xs
		maxY=Math.max.apply this,ys

		"x":minX
		"y":minY
		"width":maxX-minX
		"height":maxY-minY
		
	getBBoxInCanvasSpace = (element) ->
		getBoundingBoxInArbitrarySpace(element,element.getTransformToElement(element.ownerSVGElement))

	setupCanvasForDragging : (svg,dragSimpleRect) ->
		svg ?= document.documentElement

		isDragging = false

		#just make sure these vars are declared in the correct scope
		evtStamp = startEvtStamp = currentDraggingEntity = null

		showDraggingRect = (bbox) ->
			if bbox
				draggingRect.setAttributeNS null,"x",bbox.x
				draggingRect.setAttributeNS null,"y",bbox.y
				draggingRect.setAttributeNS null,"width",bbox.width
				draggingRect.setAttributeNS null,"height",bbox.height
				
			draggingRect.removeAttributeNS null,"display"

		hideDraggingRect = -> draggingRect.setAttributeNS null,"display","none"

		#create a rect for dragging
		if dragSimpleRect
			draggingRect = document.createElementNS svgNS,"rect"
			draggingRect.setAttributeNS null,"class","simple-dragging-rect"

			hideDraggingRect()

			svg.appendChild draggingRect

		svg.addEventListener "mousemove",(e) ->
			e.preventDefault()
			if isDragging
				tDeltaX = e.clientX - evtStamp.clientX
				tDeltaY = e.clientY - evtStamp.clientY

				toDrag = if dragSimpleRect then draggingRect else currentDraggingEntity

				translate toDrag,tDeltaX,tDeltaY

				evtStamp = e
			
		,false

		svg.addEventListener "mouseup",(e) ->
			e.preventDefault()
			if isDragging
				isDragging = false

				if dragSimpleRect
					hideDraggingRect()

					tDeltaX = e.clientX - startEvtStamp.clientX
					tDeltaY = e.clientY - startEvtStamp.clientY

					#move group
					translate currentDraggingEntity,tDeltaX,tDeltaY

					draggingRect.removeAttributeNS null,"transform"
			
		,false

		#makeSVGElementDraggable
		return (element) ->
	
			#to make him no longer draggable just remove the returned listener
			element.addEventListener "mousedown",(e) ->
				e.preventDefault()
				e.stopPropagation()
				isDragging = true
				currentDraggingEntity = element

				if dragSimpleRect
					bbox = getBBoxInCanvasSpace(currentDraggingEntity)
					showDraggingRect(bbox)

				startEvtStamp = evtStamp = e

			,false
