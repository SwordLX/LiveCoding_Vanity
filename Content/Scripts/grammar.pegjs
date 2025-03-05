program = commands: (command)+ 
{
     //remove useless comma
     let result = [];
     // this flat() is neccessary
     let row = commands.flat().map(cm=>(typeof cm === "function"?cm():cm));
     result.push(row);
     return result.join("");
}

command = _ element: (Loop/chain/function) _ ";"? _
{ return (typeof element === "function"?element():element); }

//function and chain
//define function chain
chain = a:(_ function _ ("."/"&")? )+
   { let elements = a.map (element => element[1]);
     let result = [];
      elements.forEach((el, index)=>{
      result.push(el);
      result.push("//");
     })
     return result;
    }

//define function
function = ManagerCommand/ObjectCommand

//-------------------------------- Loop Definition ---------------------------------------------------//
LoopElement = _ LoopType:(directionalSpawn/IterationCommand/BuildCircleCommand/ShaderCommand/Loop) _ ";"?
{
   //return (typeof LoopType === "function"?LoopType():LoopType);
   return LoopType;
}

Loop = _ "Loop" _ "(" _ count:(positiveInteger) _ ")" _ "{" _ commands:(LoopElement)* _  "}" _
{
   return ()=> {
                let result = [];
                for(let i = 0; i<count; i++){
                 commands.forEach(cm=>{
                 let row = (typeof cm === "function"? cm():cm);
                 result.push(row,"//");
                 })
                 //let row = commands.map(cm=>(typeof cm === "function"? cm():cm));
                 //result.push(row,"//");
                }
                return result.join("");
   }
}
//-------------------------------- End Loop Definition -------------------------------------------------//

//define command for Complex Construction
ManagerCommand = constructionCommand/SpawnCommand/ShaderCommand/IterationCommand
constructionCommand = constructionOperation/BuildCircleCommand/SetMeshCommand
SpawnCommand = directionalSpawn
ShaderCommand = SetMaterialCommand/SetColorCommand;
IterationCommand = MoveSpawnLocation/setSpawnRotation/SetGapCommand


//define the struct of construction operation
constructionOperation = rotate:rot _ angle:number _ rotateTime:positiveInteger _ objectNumber:positiveInteger _ gapLength:positiveNumber?_ 
   { if(angle>360.0) { angle = angle%360.0}
     let selected = ["construct", rotate, angle, rotateTime, objectNumber]; 
     if(gapLength) { selected.push(gapLength);}
     return selected; }

//define command for building object in circle
BuildCircleCommand
    = _ "O" _ "("_ radius:(randomNumber/positiveNumber) _")" _ "*" _ objectNumber: (randomPositiveInteger/positiveInteger) _ 
    { return ()=> {let result = ["create", "circle"];
      let r = (typeof radius === "function"?radius():radius);
      let num = (typeof objectNumber === "function"?objectNumber():objectNumber);
      result.push(r,num);
      return result;}
     }

MoveSpawnLocation = DirectSetLocation/OffsetLocation
DirectSetLocation = op:SetPositionSymbol _ parameter: vector _ { return [op, "position",parameter]; }
OffsetLocation = op:(OffsetSymbol_X/OffsetSymbol_Y/OffsetSymbol_Z) _ parameter:number _ {return ["offset",op, parameter];}

setSpawnRotation = op:rot _ parameter:(randomNumber/number) _ 
{ 
    return ()=> { 
         let result = ["rotate",op];
         let v = (typeof parameter === "function"?parameter():parameter);
         result.push(v);
      return result;      
            }
}
directionalSpawn = op:(directionalSymbol) _ parameter:(randomPositiveInteger/positiveInteger) _ {
      return ()=> {
        let result = [];
        result.push(op);
        result.push("create");
        let v = (typeof parameter === "function"?parameter():parameter);
        result.push(v);
      return result;
      }
}
SetMaterialCommand = _ parameter: assignMaterial { return ["set", parameter]}
SetColorCommand = op: colorOp _ parameter: vector _ { return ["set", op, parameter] }
SetMeshCommand = op: "=>" _ parameter: variable { return ["set", "mesh", parameter] }
SetGapCommand = op: "__" _ parameter: positiveNumber _ { return ["set","gaplength", parameter];}

//------------------------- Iterator transform definition-------------------------------------------//
SetPositionSymbol = item:(_ "->"_ ) { return "move"; }
OffsetSymbol_Z = (_ "$z"_) { return "Z";}
OffsetSymbol_Y = (_ "$y"_) { return "Y";}
OffsetSymbol_X = (_ "$x" _) { return "X";}

//------------------------End Iterator transform definition-----------------------------------------//

//------------------------- spawn symbol definition -----------------------------------------------//
directionalSymbol = forwardSymbol/backwardSymbol/leftwardSymbol/rightwardSymbol/upwardSymbol/downwardSymbol
forwardSymbol = "::" { return "forward"; }
backwardSymbol = "xx" { return "backward" ;}
leftwardSymbol = "<<" { return "leftward";}
rightwardSymbol = ">>" { return "rightward"; }
upwardSymbol = "^^" { return "upward"; }
downwardSymbol = "vv" { return "downward"; }
//-------------------------- end spawn symbol definition ---------------------------------------//

//---------------------------- Object Command -------------------------------------------------//
ObjectCommand = ObjectCommandRegion/NewObjectCommandRegion/SpecificObjectControlCommand/NewestObjectControlCommand
//Control Object
NewObjectCommandRegion = ids:lastObjects _ "{" _ commandGroup:(_ ObjectFunction _)* _"}"
   {
     let commands = commandGroup.map(arr=>arr[1]);
     let result = [];
     commands.forEach((command, index) =>{
        result.push(ids, command, "//");
     })
     return result;
   }

ObjectCommandRegion = ids:idFormat _ "{" _ commandGroup: (_ ObjectFunction _ )* _ "}"
   {
     let commands = commandGroup.map(arr=>arr[1]);
     let result = [];
     ids.forEach((item, index) => {
         commands.forEach(command => {
            result.push("Object", command, item, "//");
         })
     })
     
     return result;
   }

//Control last group (the newest objects just be created)
NewestObjectControlCommand = ids:lastObjects _ op2: objectOP _ parameter: objectParameter? _
   {
     let result = [];
     result.push("LastGroup", op2);
     if(parameter) { result.push(parameter);}
     return result;
   }

//Control 
SpecificObjectControlCommand = ids:idFormat _ op2:objectOP _ parameter: objectParameter? _
    {
       let result = [];
       ids.forEach( (item, index) => {
          result.push("Object", op2, item);
          if(parameter) { result.push(parameter);}
          result.push("//");
       })
       return result;
    }
//Object Function format
ObjectFunction = op:objectOP _ parameter: objectParameter? _ ";"? _
{
    let result = [];
    result.push(op);
    if(parameter) { result.push(parameter);}
    return result;
}

idFormat = list/IDGroup
objectOP = offsetSymbol/rot/rotRate/scale/assignMaterial/colorOp
objectParameter = variable/vector/number/randomNumber
offsetSymbol = "$" { return "offset";}
lastObjects = "[...]" { return "LastGroup";}

//define material assignment command
assignMaterial = ":" _  matName: (variable)  _ 
{  let selected = ["material" , matName];
    return selected; }

colorOp = _ "#" _ { return ["color"]}

//define rotation symbol
rot = op: ("@x"/"@y"/"@z")
   { let result = ["direction"];
     if(op == "@z") { result.push("Z"); }
     else if(op == "@x") { result.push("X"); }
     else if(op == "@y") { result.push("Y"); }
     return result;
     }

rotRate = op: ("@@x"/"@@y"/"@@z")
  {let result = ["rotateRate"];
     if(op == "@@z") { result.push("Z"); }
     else if(op == "@@x") { result.push("X"); }
     else if(op == "@@y") { result.push("Y"); }
     return result;
  }

//define scale symbol
scale = "^" { return "scale"; }

//-------------------------------------------define parameter type ----------------------------------------------//

//define variable name
variable = name :(number/word)+ { return text();}

//define list
list = "[" item:(  _ number _ ","* )+ "]"
       { console.log(item);
         return item.map ( arr => arr[1]);}

IDGroup = "[" item:( _ positiveIntegerRange _ ","*) + "]" _ rule: ("++" _ positiveInteger)?
       { let result = [];
         let filter = item.map(arr => arr[1]);
         filter.forEach(element=>{
            if(element.length<2) { result.push(element[0]);}
            else{
               let minValue = parseInt(element[0]);
               let increment = 1;
               if(rule) { increment = parseInt(rule[2]);}
               for(let maxValue = parseInt(element[1]); minValue <= maxValue; minValue+= increment){
                  console.log(minValue);
                  result.push(minValue);
               }
            }
         })
          return result;
       }

//define vector
vector 
    = "vec3"*"("  _ x: number _ "," _ y: number _ "," _ z: number _ ")"
    { return [x, y, z].join("|"); }

//define general positiveInteger

//define random float
randomNumber = _ "(" _ number01: number _ "~" _ number02: number _ ")" _
    {
       let value01 = parseFloat(number01);
       let value02 = parseFloat(number02);
       if(value01 > value02) { return  ()=> Math.random()*(value02-value01+1)+value01; }
       else  { return ()=> Math.random()*(value02-value01+1)+value01;}
    }

//define random positive integer
randomPositiveInteger = _ "(" _  min:positiveInteger _ "~" _ max:positiveInteger  _ ")" _ 
     {
             return () => Math.floor(Math.random() *( max - min + 1)) + min;
     }

//define positiveNumber range
positiveIntegerRange = integer01: positiveInteger _ "~" _ integer02: positiveInteger
        { let value01 = parseInt(integer01); 
          let value02 = parseInt(integer02);
          if(value01>value02){ return [value02, value01];}
          else if(value01<value02) { return [value01, value02]}
          else { return [value01];}
          }
          
//-----------------------define basic value type---------------------------------//
//define float
number = "-"? (([0-9]+ "." [0-9]*) / ("."? [0-9]+)) { return text(); }
//define positive number
positiveNumber = (([0-9]+ "." [0-9]*) / ("."? [0-9]+)) { return text(); }
//define integer
integerElement = "-"?[0-9]+
{ return text();}
positiveInteger = [0-9]+
{ return parseInt(text());}
word = digit+ { return text();}
digit = [a-zA-Z@]

_ "whitespace"
  = [ \t\n\r]*