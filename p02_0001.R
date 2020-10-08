###################################################################
# PROGRAM NAME: /home/jhull/nangrong?prog_r/p02_nets/p02_0001.R
# PROGRAMMER: james r. hull
# DATE: 2011 03 13
# PURPOSE: Use STATNET Package to Analyze Nang Rong Social Networks
#          This Script Puts Together Rice Labor and Sibling Networks
#          Only into a single multiplex sociogram, colored and etc.
###################################################################

###################################################################
# Set Environmental Variables and Conditions

# set the random seed for strict reproducibility
set.seed(13)

####################################################################
# Make Graphs - Two For-Loops, one for 01-09, another for 10-51

for(i in seq(1,9,1)) {

    # Define Path Names for Adjacency Matrices
    f.adj.a1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a1-adj/v0",i,"00a1.adj",sep=""))   #Raw Adjaceny File
    f.adj.a2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a2-adj/v0",i,"00a2.adj",sep=""))   #Raw Adjaceny File
    f.adj.b1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b1-adj/v0",i,"00b1.adj",sep=""))   #Raw Adjaceny File
    f.adj.b2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b2-adj/v0",i,"00b2.adj",sep=""))   #Raw Adjaceny File

    # Define Path Names for ID Sets
    f.id.a1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a1-id/v0",i,"00a1.id",sep=""))   #Raw ID Number File
    f.id.a2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a2-id/v0",i,"00a2.id",sep=""))   #Raw ID Number File
    f.id.b1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b1-id/v0",i,"00b1.id",sep=""))   #Raw ID Number File
    f.id.b2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b2-id/v0",i,"00b2.id",sep=""))   #Raw ID Number File


    f.att.all<-as.name(paste("/home/jhull/nangrong/data_paj/2000_att/v0",i,"00at.txt",sep=""))  #Text Attribute File

    f.png.loc<-as.name(paste("/home/jhull/nangrong/png_r/p02_nets/2000/a1-b2/v0",i,"00a1.png",sep=""))  #Saved PNG Graphic File
    f.title<-as.name(paste("2000: Village ",i,": Multiple Networks",sep=""))                #Title for Saved PNG

    # Load Adjacency Matrices
    adj.a1 <- as.matrix(read.table(paste(f.adj.a1)))
    adj.a2 <- as.matrix(read.table(paste(f.adj.a2)))
    adj.b1 <- as.matrix(read.table(paste(f.adj.b1)))
    adj.b2 <- as.matrix(read.table(paste(f.adj.b2)))

    # Binarize Valued Matrices (Just do it for all of them)

    adj.a1.01 <- matrix(0,nrow(adj.a1),ncol(adj.a1))
    adj.a2.01 <- matrix(0,nrow(adj.a2),ncol(adj.a2))
    adj.b1.01 <- matrix(0,nrow(adj.b1),ncol(adj.b1))
    adj.b2.01 <- matrix(0,nrow(adj.b2),ncol(adj.b2))

    adj.a1.01 [adj.a1!=0] <- 1
    adj.a2.01 [adj.a2!=0] <- 1
    adj.b1.01 [adj.b1!=0] <- 1
    adj.b2.01 [adj.b2!=0] <- 1

   # Load ID sets and Apply to Matrices
  
    id.a1 <- read.table(paste(f.id.a1))
    id.a2 <- read.table(paste(f.id.a2))
    id.b1 <- read.table(paste(f.id.b1))
    id.b2 <- read.table(paste(f.id.b2))

    colnames(adj.a1.01) <- id.a1
    rownames(adj.a1.01) <- id.a1

    colnames(adj.a2.01) <- id.a2
    rownames(adj.a2.01) <- id.a2

    colnames(adj.b1.01) <- id.b1
    rownames(adj.b1.01) <- id.b1

    colnames(adj.b2.01) <- id.b2
    rownames(adj.b2.01) <- id.b2

    # Create Edge Colors Matrix (2 dimensional)

    colors.01 <- ifelse((adj.a1.01!=0),"a1","0")
    colors.01 <- ifelse((adj.a2.01!=0),"a2",colors.01)
    colors.01 <- ifelse((adj.b1.01!=0),"b1",colors.01)
    colors.01 <- ifelse((adj.b2.01!=0),"b2",colors.01)

    multi.01 <- adj.a1.01+adj.a2.01+adj.b1.01+adj.b2.01

    colors.02 <- ifelse((multi.01>1),(as.character(multi.01)),colors.01)

    #Assign Colors to Single Relations and Shades of Grey to Multiple Relations

    color.array <- rbind(c("a1","green"),    #Paid Labor = Green
                         c("a2","yellow"),    #Unaid Labor = Light Yellow
                         c("b1","blue"),     #Male Sibling = Blue
                         c("b2","blue"),     #Female Sibling = (Also) Blue  
                         c("2","gray72"),     #Multiplex (Any Two) = Lightest Grey
                         c("3","gray47"),     #Multiplex (Any Three) = Mid-Range Grey
                         c("4","gray23")      #Multiplex (Any Four) = Mid-Range Grey   
                        )
    colors.03 <- lookup(colors.02, color.array)

    # Create 3-dimensional matrix (Z-dimension is the specific relation)
    # Paid and Unpaid Labor
    values.01  <- abind(adj.a1.01,adj.a2.01,along=3,new.names=c("paid","unpaid"))
    # Male and Female Siblings
    values.02  <- abind(adj.b1.01,adj.b2.01,along=3,new.names=c("male sib","female sib"))
    # (1) Paid Labor (2) Unpaid Labor (3) Male Siblings (4) Female Siblings
    values.03  <- abind(values.01,values.02,along=3)
 
    # Load Attribute File
    att <- read.table(file=paste(f.att.all), header=F,col.names=c("RICE","IS_HH","ALL_PWRK","ALL_PWAG",
                      "ALL_UWRK","ALL_UWAG","ALL_WRKS","ALL_WAGE"))

    # Recode Attributes for Current Graphical Display
    att$RICE2 [att$RICE==0] <- "blue"
    att$RICE2 [att$RICE==1] <- "red"
    att$ALL_WRK2 [att$ALL_WRKS==0] <- 0.5
    att$ALL_WRK2 [att$ALL_WRKS > 0 & att$ALL_WRKS <= 10] <- 0.75
    att$ALL_WRK2 [att$ALL_WRKS > 10 & att$ALL_WRKS <= 20] <- 1.0
    att$ALL_WRK2 [att$ALL_WRKS > 20 & att$ALL_WRKS <= 30] <- 1.25
    att$ALL_WRK2 [att$ALL_WRKS > 30 & att$ALL_WRKS <= 40] <- 1.5
    att$ALL_WRK2 [att$ALL_WRKS > 40 & att$ALL_WRKS <= 50] <- 1.75
    att$ALL_WRK2 [att$ALL_WRKS > 50] <- 2.0

    my.vertex.col <- as.vector(att$RICE2)  
    my.vertex.cex <- as.vector(att$ALL_WRK2)  

    # Open Graphics File
    png(file=paste(f.png.loc), bg="white",height=960, width=960)

    #Generate Complete Multiplex Graph with all vertices and edges properly colored/sized
    gplot(values.03[,,1] | values.03[,,2] | values.03[,,3] | values.03[,,4], 
          displaylabels=FALSE,
          edge.col=colors.03,
          vertex.col = my.vertex.col,
          vertex.cex=my.vertex.cex,
          vertex.sides=20,
          edge.lwd=2,
          arrowhead.cex=0.75      
          )

    #Add Title To Graphic
    title(main=paste(f.title), col.main="black", font.main=20)

    #Add Legend #1 To Graphic
    legend(x="bottom", 
           inset=0.03, 
           c("Rice Growing Household", "Non-Rice-Growing Household"),
           pch=20,
           cex=1, 
           pt.cex=3, 
           col=c("red","blue"), 
           bty="n",
           horiz=TRUE
          )

    #Add Legend #1 To Graphic
    legend(x="bottom",
           c("Paid Labor Tie","Unpaid Labor Tie","Sibling Tie","Multiplex Tie (2)","Multiplex Tie (3)","Multiplex Tie (4)"),
           inset=0.015,
           cex=1, 
           col=c("green","yellow","blue","gray72","gray47","gray23"), 
           lwd=3, 
           bty="n",
           horiz=TRUE
          )

    #Add Legend #3 To Graphic
    legend(x="bottom", 
           c("Vertices Sized by the Total Number of Rice Laborers Used"),
           cex=1,
           bty="n")

    # Clean Up to Prepare for Next Iteration
      rm("f.adj.a1",
          "f.adj.a2",
          "f.adj.b1",
          "f.adj.b2",
          "adj.a1.01",
          "adj.a2.01",
          "adj.b1.01",
          "adj.b2.01",
          "f.id.a1",
          "f.id.a2",
          "f.id.b1",
          "f.id.b2",
          "f.att.all",
          "f.png.loc",
          "f.title",
          "adj.a1",
          "adj.a2",
          "adj.b1",
          "adj.b2",
          "id.a1",
          "id.a2",
          "id.b1",
          "id.b2",
          "multi.01",
          "colors.01",
          "colors.02",
          "colors.03",
          "values.01",
          "values.02",
          "values.03",
          "my.vertex.col",
          "my.vertex.cex"
        )

    # Flush Graphic Output to File
    dev.off()

} # End Of: Make Graphs


for(i in seq(10,51,1)) {

    # Define Path Names for Adjacency Matrices
    f.adj.a1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a1-adj/v",i,"00a1.adj",sep=""))   #Raw Adjaceny File
    f.adj.a2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a2-adj/v",i,"00a2.adj",sep=""))   #Raw Adjaceny File
    f.adj.b1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b1-adj/v",i,"00b1.adj",sep=""))   #Raw Adjaceny File
    f.adj.b2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b2-adj/v",i,"00b2.adj",sep=""))   #Raw Adjaceny File

    # Define Path Names for ID Sets
    f.id.a1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a1-id/v",i,"00a1.id",sep=""))   #Raw ID Number File
    f.id.a2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/a2-id/v",i,"00a2.id",sep=""))   #Raw ID Number File
    f.id.b1<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b1-id/v",i,"00b1.id",sep=""))   #Raw ID Number File
    f.id.b2<-as.name(paste("/home/jhull/nangrong/data_paj/2000/b2-id/v",i,"00b2.id",sep=""))   #Raw ID Number File


    f.att.all<-as.name(paste("/home/jhull/nangrong/data_paj/2000_att/v",i,"00at.txt",sep=""))  #Text Attribute File

    f.png.loc<-as.name(paste("/home/jhull/nangrong/png_r/p02_nets/2000/a1-b2/v",i,"00a1.png",sep=""))  #Saved PNG Graphic File
    f.title<-as.name(paste("2000: Village ",i,": Multiple Networks",sep=""))                #Title for Saved PNG

    # Load Adjacency Matrices
    adj.a1 <- as.matrix(read.table(paste(f.adj.a1)))
    adj.a2 <- as.matrix(read.table(paste(f.adj.a2)))
    adj.b1 <- as.matrix(read.table(paste(f.adj.b1)))
    adj.b2 <- as.matrix(read.table(paste(f.adj.b2)))

    # Binarize Valued Matrices (Just do it for all of them)

    adj.a1.01 <- matrix(0,nrow(adj.a1),ncol(adj.a1))
    adj.a2.01 <- matrix(0,nrow(adj.a2),ncol(adj.a2))
    adj.b1.01 <- matrix(0,nrow(adj.b1),ncol(adj.b1))
    adj.b2.01 <- matrix(0,nrow(adj.b2),ncol(adj.b2))

    adj.a1.01 [adj.a1!=0] <- 1
    adj.a2.01 [adj.a2!=0] <- 1
    adj.b1.01 [adj.b1!=0] <- 1
    adj.b2.01 [adj.b2!=0] <- 1

   # Load ID sets and Apply to Matrices
  
    id.a1 <- read.table(paste(f.id.a1))
    id.a2 <- read.table(paste(f.id.a2))
    id.b1 <- read.table(paste(f.id.b1))
    id.b2 <- read.table(paste(f.id.b2))

    colnames(adj.a1.01) <- id.a1
    rownames(adj.a1.01) <- id.a1

    colnames(adj.a2.01) <- id.a2
    rownames(adj.a2.01) <- id.a2

    colnames(adj.b1.01) <- id.b1
    rownames(adj.b1.01) <- id.b1

    colnames(adj.b2.01) <- id.b2
    rownames(adj.b2.01) <- id.b2

    # Create Edge Colors Matrix (2 dimensional)

    colors.01 <- ifelse((adj.a1.01!=0),"a1","0")
    colors.01 <- ifelse((adj.a2.01!=0),"a2",colors.01)
    colors.01 <- ifelse((adj.b1.01!=0),"b1",colors.01)
    colors.01 <- ifelse((adj.b2.01!=0),"b2",colors.01)

    multi.01 <- adj.a1.01+adj.a2.01+adj.b1.01+adj.b2.01

    colors.02 <- ifelse((multi.01>1),(as.character(multi.01)),colors.01)

    #Assign Colors to Single Relations and Shades of Grey to Multiple Relations

    color.array <- rbind(c("a1","green"),    #Paid Labor = Green
                         c("a2","yellow"),    #Unaid Labor = Light Yellow
                         c("b1","blue"),     #Male Sibling = Blue
                         c("b2","blue"),     #Female Sibling = (Also) Blue  
                         c("2","gray72"),     #Multiplex (Any Two) = Lightest Grey
                         c("3","gray47"),     #Multiplex (Any Three) = Mid-Range Grey
                         c("4","gray23")      #Multiplex (Any Four) = Mid-Range Grey   
                        )
    colors.03 <- lookup(colors.02, color.array)

    # Create 3-dimensional matrix (Z-dimension is the specific relation)
    # Paid and Unpaid Labor
    values.01  <- abind(adj.a1.01,adj.a2.01,along=3,new.names=c("paid","unpaid"))
    # Male and Female Siblings
    values.02  <- abind(adj.b1.01,adj.b2.01,along=3,new.names=c("male sib","female sib"))
    # (1) Paid Labor (2) Unpaid Labor (3) Male Siblings (4) Female Siblings
    values.03  <- abind(values.01,values.02,along=3)
 
    # Load Attribute File
    att <- read.table(file=paste(f.att.all), header=F,col.names=c("RICE","IS_HH","ALL_PWRK","ALL_PWAG",
                      "ALL_UWRK","ALL_UWAG","ALL_WRKS","ALL_WAGE"))

    # Recode Attributes for Current Graphical Display
    att$RICE2 [att$RICE==0] <- "blue"
    att$RICE2 [att$RICE==1] <- "red"
    att$ALL_WRK2 [att$ALL_WRKS==0] <- 0.5
    att$ALL_WRK2 [att$ALL_WRKS > 0 & att$ALL_WRKS <= 10] <- 0.75
    att$ALL_WRK2 [att$ALL_WRKS > 10 & att$ALL_WRKS <= 20] <- 1.0
    att$ALL_WRK2 [att$ALL_WRKS > 20 & att$ALL_WRKS <= 30] <- 1.25
    att$ALL_WRK2 [att$ALL_WRKS > 30 & att$ALL_WRKS <= 40] <- 1.5
    att$ALL_WRK2 [att$ALL_WRKS > 40 & att$ALL_WRKS <= 50] <- 1.75
    att$ALL_WRK2 [att$ALL_WRKS > 50] <- 2.0

    my.vertex.col <- as.vector(att$RICE2)  
    my.vertex.cex <- as.vector(att$ALL_WRK2)  

    # Open Graphics File
    png(file=paste(f.png.loc), bg="white",height=960, width=960)

    #Generate Complete Multiplex Graph with all vertices and edges properly colored/sized
    gplot(values.03[,,1] | values.03[,,2] | values.03[,,3] | values.03[,,4], 
          displaylabels=FALSE,
          edge.col=colors.03,
          vertex.col = my.vertex.col,
          vertex.cex=my.vertex.cex,
          vertex.sides=20,
          edge.lwd=2,
          arrowhead.cex=0.75      
          )

    #Add Title To Graphic
    title(main=paste(f.title), col.main="black", font.main=20)

    #Add Legend #1 To Graphic
    legend(x="bottom", 
           inset=0.03, 
           c("Rice Growing Household", "Non-Rice-Growing Household"),
           pch=20,
           cex=1, 
           pt.cex=3, 
           col=c("red","blue"), 
           bty="n",
           horiz=TRUE
          )

    #Add Legend #1 To Graphic
    legend(x="bottom",
           c("Paid Labor Tie","Unpaid Labor Tie","Sibling Tie","Multiplex Tie (2)","Multiplex Tie (3)","Multiplex Tie (4)"),
           inset=0.015,
           cex=1, 
           col=c("green","yellow","blue","gray72","gray47","gray23"), 
           lwd=3, 
           bty="n",
           horiz=TRUE
          )

    #Add Legend #3 To Graphic
    legend(x="bottom", 
           c("Vertices Sized by the Total Number of Rice Laborers Used"),
           cex=1,
           bty="n")

    # Clean Up to Prepare for Next Iteration
      rm("f.adj.a1",
          "f.adj.a2",
          "f.adj.b1",
          "f.adj.b2",
          "adj.a1.01",
          "adj.a2.01",
          "adj.b1.01",
          "adj.b2.01",
          "f.id.a1",
          "f.id.a2",
          "f.id.b1",
          "f.id.b2",
          "f.att.all",
          "f.png.loc",
          "f.title",
          "adj.a1",
          "adj.a2",
          "adj.b1",
          "adj.b2",
          "id.a1",
          "id.a2",
          "id.b1",
          "id.b2",
          "multi.01",
          "colors.01",
          "colors.02",
          "colors.03",
          "values.01",
          "values.02",
          "values.03",
          "my.vertex.col",
          "my.vertex.cex"
        )

    # Flush Graphic Output to File
    dev.off()

} # End Of: Make Graphs

###################################################################
# Clean Up and Close
delete.all <- function() 
      rm(list=ls(pos=.GlobalEnv), pos=.GlobalEnv) 
delete.all()