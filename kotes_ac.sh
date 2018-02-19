_kotes()
{
    local cur prev opts base                                                       
    COMPREPLY=()                                                                   
    cur="${COMP_WORDS[COMP_CWORD]}"                                                
    prev="${COMP_WORDS[COMP_CWORD-1]}"                                             
                                                                                   
    opts="-a -t -h -v"                                                             
                                                                                   
    case "${prev}" in                                                              
            -t)                                                                    
            local tags=$(kotes -l | sed  's/#\(.*\)/\1/g')
            COMPREPLY=( $(compgen -W "${tags}" -- ${cur}) )                        
            return 0                                                               
            ;;                                                                     
        *)                                                                         
        ;;                                                                         
    esac                                                                           
                                                                                   
   COMPREPLY=($(compgen -W "${opts}" -- ${cur}))                                   
   return 0                                                                        
}                                                                                  
complete -F _kotes kotes   
