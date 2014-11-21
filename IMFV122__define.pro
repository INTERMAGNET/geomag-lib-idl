; docformat = 'rst'
;+
; :author:
;   Charles Blais, Geomagnetic Laboratory of Canada, 2011
;-

;+
; :description:
;   Constructor.
; 
; :params:
;   file : in, required, type=string
;     file name of IMFV122 file
;-
function IMFV122::init, file
  compile_opt idl2
  
  self.file = file
  
  return, 1
end

;+
; :description:
;   Read IAGA2002 file
;-
function IMFV122::read
  compile_opt idl2
  
  if ~file_test(self.file) then $
    message, 'File '+self.file+' can not be found'
  
  if stregex(self.file, '\.gz$', /boolean) then compress = 1 $
  else compress = 0
  
  openr, lun, self.file, /get_lun, compress = compress
  
  idx = 0
  while ~eof(lun) do begin
    line = ''
    readf, lun, line
    if stregex(line, '^[A-Z]{3} [A-Z]{3}[0-9]{4} [0-9]{3} [0-9]{2} [A-Z]{4}', /boolean) then begin
    
      year = 2000 + fix(strmid(line, 9, 2))
      day = fix(strmid(line,7,2))
      doy = fix(strmid(line,12,3))
      hour = fix(strmid(line,16,2))
      minute = 0
      datetime = julday(1,doy,year,hour,minute,0)
      components = strmid(line,19,4)
      if n_elements(used_components) eq 0 then begin
        used_components = components
        data = create_struct( 'time' , replicate(!values.d_nan,1440), $
          strmid(components,0,1) , replicate(!values.f_nan, 1440), $
          strmid(components,1,1) , replicate(!values.f_nan, 1440), $
          strmid(components,2,1) , replicate(!values.f_nan, 1440), $
          strmid(components,3,1) , replicate(!values.f_nan, 1440))
          
      endif else if used_components ne components then message, 'Components have changes from '+used_components+' to '+components
      
    endif else if stregex(line, '^[0-9\+\-]+', /boolean) then begin
      
      if n_elements(data) eq 0 then message, 'Header of IMF file is missing'
      
      extract = strsplit(line, " ", /extract, count = count)
      if count ne 8 then message, 'Incomplete IMF file'
      
      data.time[idx] = datetime + (idx mod 60)/1440.0
      for i=0,3 do begin
        ; we must extract the values from the structure
        ; before manipulating
        ; with IDL6.2, we noticed that data.(i)[loc] does not work
        temp = data.(i+1)
        temp[idx] = float(extract[i])/10.0
        data.(i+1) = temp
      endfor
      idx = idx + 1
      
      data.time[idx] = datetime + (idx mod 60)/1440.0
      for i=0,3 do begin
        ; we must extract the values from the structure
        ; before manipulating
        ; with IDL6.2, we noticed that data.(i)[loc] does not work
        temp = data.(i+1)
        temp[idx] = float(extract[i+4])/10.0
        data.(i+1) = temp
      endfor
      idx = idx + 1
    
    endif else message, 'Could not read IMF file because of bad line'
  endwhile
  
  free_lun, lun
  
   ; replace null values with IDL null values
  tags = tag_names(data)
  n = n_elements(tags)
  for i=n-4,n-1 do begin
    loc = where(data.(i) ge 88888.00, count)
    if count ne 0 then begin
      ; we must extract the values from the structure
      ; before manipulating
      ; with IDL6.2, we noticed that data.(i)[loc] does not work
      temp = data.(i)
      temp[loc] = !values.f_nan
      data.(i) = temp
    endif
  endfor
  
  return, data
  
end

;+
; :description:
;   Destructor.
;-
pro IMFV122::cleanup
  compile_opt idl2
  
end


;+
; :description:
;   Class data definition procedure.
;-
pro IMFV122__define
  compile_opt idl2
  
  null = {IMFV122, $
    file : '' }
end

