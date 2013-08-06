###
*******************************************************
* app.coffee
* 
* Author: Raadad Elsleiman
*
* client for node-workout application
*******************************************************
###


$(document).ready ->
  root = window
  root._test = {}
  #consumes the exervises rest endpoint to get a list of exercises that can be used
  $.ajax 
    url:'/exercises/'
    dataType: 'jsonp'
    success: (results) ->
      model = {}
      data = results  #stores that list of exercises inside "data"
      #setups the sliders and bind events

      intensityValues = ["","Low","Medium","High","Extreme"]
      
      $("#intenSlider").slider
        range: "min"
        value: 3
        min: 1
        max: 4
        step: 1
        slide: (event, ui) ->
          $("#intenDisp").html intensityValues[ui.value]
          generateModel($("#timeSlider").slider("value"),ui.value); #this is re generate a workout based on new parameters
          appRender(); #because the model has changed we will need to re-render the page
      
      $("#timeSlider").slider
        range: "min"
        value: 10
        min: 10
        max: 60
        step: 10
        slide: (event, ui) ->
          $("#timeDisp").html ui.value + " Minutes"
          generateModel(ui.value,$("#intenSlider").slider("value")); #this is re generate a workout based on new parameters
          appRender();  #because the model has changed we will need to re-render the page
     
      #set initial values 
      $("#intenDisp").html intensityValues[$("#intenSlider").slider("value")]
      $("#timeDisp").html $("#timeSlider").slider("value") + " Minutes"
      

      #all application state is stored inside model.state
      #this method will overwrite an existing model with new parameters and reset all state
      generateModel = (time,intensity) ->
        throw new Error("Bad Argument Error") if typeof time != 'number'
        throw new Error("Bad Argument Error") if typeof intensity != 'number'

        obj = {}  
        list = _.shuffle(data) #randomizes the workouts
        obj.intensity = intensity  
        obj.exersices = [list[0],list[1],list[2]] #picks the first 3 random workouts
        obj.sets = (_.shuffle(obj.exersices) for i in [1..(6 - obj.intensity)]) #creates sets with exercises in random orders

        obj.originalTime = time * 60 #time is stored in seconds, however is input in minutes
        obj.setLength = obj.originalTime / obj.sets.length #determines how long each set will go for
        obj.state = {}
        obj.state.running = false #This is required to see if a workout is started or not
        obj.state.time = obj.originalTime+1 #time counts down, so it starts from the total workout time

        obj.countDown = ->
          obj.state.time--  #this method is expected to run every second, so this will decrement time by 1 for each second       
          obj.state.timeElapsed = obj.originalTime - obj.state.time #shows how much time has passed         
          obj.state.currentSet = Math.floor(obj.state.timeElapsed/model.setLength) #Determines which set is currently running

          obj.state.currentExerc = Math.floor (((obj.originalTime - obj.state.time) % obj.setLength) / obj.setLength * 100) / 33.33333333333333333333333333333333
          obj.state.percentageExerc = ((((obj.originalTime - obj.state.time) % obj.setLength) / obj.setLength * 100) % 33.33333333333333333333333333333333) / 33.33333333333333333333333333333333 * 100
          obj.state.percentageSet = ((obj.originalTime - obj.state.time) % obj.setLength) / obj.setLength * 100
          obj.state.percentageOverall = (obj.originalTime - obj.state.time) / obj.originalTime *100

        obj.countDown(); #initializes all the properties of the model.state object
        model = obj #assigns it so ti can be accessed externally
        return model # makes model testable


      # Area's of the screen a completly re-rendered, this is 
      # better for performance as  DOM manipulation is expensive,
      # and much easy to manage The use of Raw html, and no 
      # templating engine is beacuse the  templates are re-rendered 
      # every second and can cause problems on a low spec device if
      # a heavy templating engine was used

      renderWorkoutOutline = ->
        template = """
        <a class="stdbtn">Selected Exercises</a>
        <span> </span>
        <div class="content widgetgrid">
          <div class="ui-widget-content">
            <ul class="activitylist">
        """
        for i in model.exersices
          template+= """
                <li class="user">
                  <a><strong>#{i.name} - #{i.part} Workout</strong></a>
                </li>
        """
        template += """
              </ul>
            </div>
          </div>
          <div class="content widgetgrid">
        """
        for i,k in model.sets
          template += """
              <div class="widgetbox">
                <div class="title">
                  <h2 class="tabbed">
                    <span>SET #{k+1}</span>
                  </h2>
                </div>
                <div class="ui-widget-content">
                  <ul class="activitylist">
                  """
          for x in i 
            template = template+="""
                      <li class="user">
                        <a>#{ Math.floor((model.setLength/3)/x.time)} x <strong>#{x.name}</strong></a>
                    """
          template = template+="""
                    </li>
                  </ul>
                </div>
              </div>
        """
        template +="</div> <br>"
        $("#workoutOutline").html(template)

      renderWorkoutWidget = ->
        template = "
              <button id='workoutButton' class='stdbtn #{if model.state.time < 1 then "btn_lime" else if model.state.running then 'btn_red' else 'btn_yellow' }'>
                #{if model.state.time < 1 then "Create New Workout" else if model.state.running then 'Stop Workout' else 'Start Workout'}      
              </button>
        "
        if(model.state.running and model.state.time > 0)
          template+= "
                <div class='progress'>
                  <div class='bar2'>
                    <div style='width:#{model.state.percentageSet}%' class='value bluebar'>SET #{model.state.currentSet+1}</div>
                  </div>
                </div>
                "
          for i, k in model.sets[model.state.currentSet]
            template+= "
                <button disabled='disabled' class='stdbtn #{if k ==  model.state.currentExerc then "btn_blue" else "" }'>#{i.time} x #{i.name}</button>
              "

          template += "
                  <div class='progress'>
                    <div class='bar2'>
                      <div style='width:#{model.state.percentageExerc}%' class='value orangebar'>#{model.sets[model.state.currentSet][model.state.currentExerc].name}</div>
                    </div>
                  </div>    
                  <div class='progress'>
                    <div class='bar2'>
                      <div style='width:#{model.state.percentageOverall}%' class='value redbar'>Overall Progress </div>
                   </div>
                  </div>  
                "
        else if model.state.time < 1
          template += "
            <br>
            <br>
            <div class='notification msgsuccess'>
                          <a class='close'></a>
                          <p>Great Job</p>
                      </div>
             "

        $("#workoutWidget").html(template)
        $("#workoutButton").click ->
          if(model.state.time > 0)
            model.state.running = !model.state.running
          else
            generateModel($("#timeSlider").slider("value"),$("#intenSlider").slider("value"))
          appRender();

      #This method will re-draw all parts of the screen that could change
      appRender = ->
        renderWorkoutWidget()
        renderWorkoutOutline()
      
      #this construct allows for the screen to be rendered and the state to be manipulated every second,
      #this is needed as this is a time based application
      timer = ->
        everySecond = ->
          s = setTimeout run , 1000
        run = ->
          if model.state.running
            if model.state.time < 0
              model.state.running = false
            model.countDown()
            appRender();
          everySecond()        
        everySecond()
      

      generateModel(10,3); # kicks off and generates a model
      timer() # starts the ticker
      appRender() #renders the widgets

      #Make code testable
      root._test.data = data
      root._test.generateModel = generateModel
      root._test.appRender = appRender