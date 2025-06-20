window.Audio = {
  __hasInput: false,
  ctx: null,
  bins:null,

  start( bins=null ) {
    if( Audio.__hasInput === false ) {
      Audio.ctx = new AudioContext()
      Audio.createInput().then( input => {
        if( bins !== null ) Audio.bins = bins
        Audio.createFFT()
        input.connect( Audio.FFT )

        Audio.interval = setInterval( Audio.fftCallback, 0.01) //default = 1000/60
        //window.FFT = Audio.FFT
      })
      Audio.__hasInput = true
    }else{
      if( bins !== null ) Audio.bins = bins
    }
  },

  createInput() {
    console.log( 'connecting audio input...' )
    
    const p = new Promise( resolve => {
      navigator.mediaDevices.getUserMedia({ audio:true, video:false })
        .then( stream => {
          console.log( 'audio input connected' )
          Audio.input = Audio.ctx.createMediaStreamSource( stream )
          //Audio.mediaStreamSource.connect( Gibberish.node )
          Audio.__hasInput = true
          resolve( Audio.input )
        })
        .catch( err => { 
          console.log( 'error opening audio input:', err )
        })
    })
    return p
  },

  createFFT() {
    Audio.FFT = Audio.ctx.createAnalyser()

    let __windowSize = 512
    Object.defineProperty( Audio, 'windowSize', {
      configurable:true,
      get() { return __windowSize },
      set(v){
        __windowSize = v
        Audio.FFT.fftSize = v 
        Audio.FFT.values = new Uint8Array( Audio.FFT.frequencyBinCount )
      }
    })

    Audio.windowSize = 512
  },

  fftCallback() {
    Audio.FFT.getByteFrequencyData( Audio.FFT.values )
    
    /* let lowSum, midSum, highSum, lowCount, midCount, highCount
    lowSum = midSum = highSum = lowCount = midCount = highCount = 0 */

    //Instrument
    let KickDrumSum, BassSum, PianoSum, VocalsSum, ViolinSum, HarpSum, CymbalsSum, 
    KickDrumCount, BassCount, PianoCount, VocalsCount, ViolinCount, HarpCount, CymbalCount;
    KickDrumSum = BassSum = PianoSum = VocalsSum = ViolinSum = HarpSum = CymbalsSum  = 0
    KickDrumCount = BassCount = PianoCount = VocalsCount = ViolinCount = HarpCount = CymbalCount = 0

    let frequencyCounter = 0

    // does this start at 0Hz? ack... can't remember... does it include DC offset?
    const hzPerBin = (Audio.ctx.sampleRate / 2) / Audio.FFT.frequencyBinCount
    //const lowRange = 150, midRange = 1400, highRange = Audio.ctx.sampleRate / 2

    // Instrument Pitch Range
    const KickDrumRange = 80, BassRange = 180, PianoRange = 400, VocalsRange = 1200, HarpRange = 4000, CymbalsRange = Audio.ctx.sampleRate / 2

    if( Audio.bins === null ) {
      for( let i = 1; i < Audio.FFT.frequencyBinCount; i++ ) {
        /* if( frequencyCounter < lowRange ) {
          lowSum += Audio.FFT.values[ i ]
          lowCount++
        }else if( frequencyCounter < midRange ) {
          midSum += Audio.FFT.values[ i ]
          midCount++
        }else{
          highSum += Audio.FFT.values[ i ]
          highCount++
        } */

        if(frequencyCounter < KickDrumRange){
          KickDrumSum += Audio.FFT.values[ i ]
          KickDrumCount++
        }else if(frequencyCounter < BassRange){
          BassSum += Audio.FFT.values[ i ]
          BassCount++
        }else if( frequencyCounter < PianoRange){
          PianoSum += Audio.FFT.values[ i ]
          PianoCount++
        }else if( frequencyCounter < VocalsRange){
          VocalsSum += Audio.FFT.values[ i ]
          VocalsCount++
        }else if( frequencyCounter < HarpRange ){
          HarpSum += Audio.FFT.values[ i ]
          HarpCount++
        }else{
          CymbalsSum += Audio.FFT.values[ i ]
          CymbalCount++
        }
        
        frequencyCounter += hzPerBin
      }


      /* Audio.low = (lowSum / lowCount) / 255
      Audio.mid = (midSum / midCount) / 255 || 0
      Audio.high = (highSum / highCount) / 255 */
      
      //let audios = [Audio.low, Audio.mid, Audio.high]
      //sendOSC(audios)

      let KickDrmSound = (KickDrumSum / KickDrumCount)/255
      let BassSound = (BassSum / BassCount) / 255 || 0
      let PianoSound = (PianoSum / PianoCount) / 255 || 0
      let VocalsSound = (VocalsSum / VocalsCount) / 255 || 0
      let HarpSound = (HarpSum / HarpCount) /255 || 0
      let CymbalSound = (CymbalsSum / CymbalCount) /255

      let InstrumentSound = [KickDrmSound, BassSound, PianoSound, VocalsSound, HarpSound, CymbalSound]
      let audioAddress = "/Audio/FFT"
      let args = InstrumentSound.map( a => {
        const numericValue = parseFloat(a)
        const arg = {
          type: 'f',
          value: numericValue
        }
        
        return arg
      })
      sendOSC(audioAddress, args)

    }else{
      const sums = {}
      for( let bin = 0; bin < Audio.bins.length; bin++ ) {
        const frequency = Audio.bins[ bin ]

        sums[ bin ] = { count: 0, value: 0 }

        for( let i = 1; i < Audio.FFT.frequencyBinCount; i++ ) {
          if( frequencyCounter < frequency ) {
            sums[ bin ].value += Audio.FFT.values[i]
            sums[ bin ].count++
            frequencyCounter += hzPerBin
          }else{
            break
          }
        }
        Audio[ bin ] = (sums[ bin ].value / sums[ bin ].count) / 255 
      }
    }
  }
}