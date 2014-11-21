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
;     file name of IAGA2002 file
;-
function IAGA2002::init, file
  compile_opt idl2
  
  self.file = file
  ;year,month,day,hour,minute,second,4xcomp
  self.read_format = '((i4,4(1x, i2), x, f6.3, 7x, 4(x,f9.2)))'
  
  return, 1
end

;+
; :description:
;   Read IAGA2002 file
;-
function IAGA2002::read
  compile_opt idl2
  
  if ~file_test(self.file) then $
    message, 'File '+self.file+' can not be found'
  
  if stregex(self.file, '\.gz$', /boolean) then compress = 1 $
  else compress = 0
  
  openr, lun, self.file, /get_lun, compress = compress
  ;read the header of the file
  count = 0
  while ~eof(lun) do begin
    line = ''
    readf, lun, line
    count++
    if stregex(line, '^DATE', /boolean) then begin
      struct = self->__decode_header(line)
      break
    endif
  endwhile
  
  lines = file_lines(self.file, compress=compress) - count
  if lines le 0 then $
    message, 'No content in '+self.file+', can not read'
  data = replicate(struct, lines)
  readf, lun, data, format=self.read_format
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
  
  ; knowing the structure last 4 tags are data, the other are time
  ; to be converted into julian day format
  time = julday(data.month, data.day, data.year, data.hour, data.minute, data.second)
  data = create_struct('time', time, $
    tags[n-4], data.(n-4), $
    tags[n-3], data.(n-3), $
    tags[n-2], data.(n-2), $
    tags[n-1], data.(n-1))
  
  return, data
  
end

;+
; :description:
;   Decode header of the file and return the structure
;   that data will be written too.
; 
; :params:
;   line : in, required, type=string
;     header line expected by program, line must be in the format
;     DATE       TIME         DOY     OBSX      OBSY      OBSZ      OBSF   |  
;-
function IAGA2002::__decode_header, line
  compile_opt idl2
  
  content = strsplit(line, " ", count=count, /extract)
  if count ne 8 then $
    message, 'Could not decode header of IAGA2002 file, 8 elements expected'
  
  ; knowing the format line we are reading (see read_format variable)
  ; we can start the structure
  ; doy is ignored
  struct = { year : 0, month : 0, day : 0, hour : 0, minute : 0, second : 0.0 }
  
  ; verify that the axis are in the format OBSx
  ; add add to structure
  for i=3,6 do begin
    if ~stregex(content[i], "^[A-Z]{4}$", /boolean) then $
      message, 'Invalid header for axis '+content[i]
    comp = strmid(content[i], 3)
    struct = create_struct(struct, comp, 0.0)
  endfor
  
  return, struct
  
end

;+
; :description:
;   Destructor.
;-
pro IAGA2002::cleanup
  compile_opt idl2
  
end


;+
; :description:
;   Class data definition procedure.
;-
pro IAGA2002__define
  compile_opt idl2
  
  null = {IAGA2002, $
    file : '', $
    read_format : '' }
end

