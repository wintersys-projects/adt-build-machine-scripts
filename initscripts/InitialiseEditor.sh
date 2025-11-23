if ( [ ! -f /root/.vimrc-adt ] )
then
        /bin/echo "
        set mouse=r
        syntax on
        filetype indent on
        set smartindent
        set fo-=or
        autocmd BufRead,BufWritePre *.sh normal gg=G " > /root/.vimrc-adt

        /bin/echo "alias vim='/usr/bin/vim -u /root/.vimrc-adt'" >> /root/.bashrc
        /bin/echo "alias vi='/usr/bin/vim -u /root/.vimrc-adt'" >> /root/.bashrc
fi
