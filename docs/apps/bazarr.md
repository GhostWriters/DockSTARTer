# Bazarr

[Bazarr](https://www.bazarr.media/) is a companion application to Sonarr and Radarr. It can manage and download subtitles based on your requirements. You define your preferences by TV show or movie and Bazarr takes care of everything for you.

The GIT Repository for Bazarr is located at [https://github.com/linuxserver/docker-bazarr](https://github.com/linuxserver/docker-bazarr)

By default, the DockSTARTer configuration of Bazarr will map to the following volumes:

```yaml
      - ${DOCKERSHAREDDIR}:/shared
      - ${MEDIADIR_MOVIES}:/movies
      - ${MEDIADIR_TV}:/tv
```

If you have any media outside of those locations, you'll need to create an [Override](https://dockstarter.com/advanced/overrides/) specifically for those volumes.
