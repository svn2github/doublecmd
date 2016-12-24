-- Simple example of how to write wdx-scripts

function ContentSetDefaultParams(IniFileName,PlugApiVerHi,PlugApiVerLow)
  --Initialization code here
end

first=true;
function ContentGetSupportedField(Index)
  if (not first) then 
    return '','', 0; -- ft_nomorefields
  end 

  if (first) then
    first=false;
    return 'FieldName','', 8; -- FieldName,Units,ft_string
  end  
end

function ContentGetDefaultSortOrder(FieldIndex)
  return 1; --or -1
end

function ContentGetDetectString()
  return 'EXT="TXT"'; -- return detect string
end

function ContentGetValue(FileName, FieldIndex, UnitIndex, flags)
  if (FieldIndex == 0) then
    return "FieldValue0"; -- return string
  elseif (FieldIndex == 1) then
    return "FieldValue1";
  elseif (FieldIndex == 2) then
    return "FieldValue2";
  end
  return nil; -- invalid
end

--function ContentGetSupportedFieldFlags(FieldIndex)
  --return 0; -- return flags
--end

--function ContentStopGetValue(Filename)
--end
