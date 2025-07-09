# goal: setup basic OA and KL data for use in the script 'original_script_rewrite_function.R'

# in future will convert to a function and allow arguments, but returns many objects
# at the moment so will need restructing, or some sort of collapse into a list and then
# reinstatment of the individual objects

# % add KL levels
# kl0 = am.oa == 0;
# am.kl0 = kl0;
am$kl0 <- ifelse(am$oa == 1, 1, 0)

# kl = zeros(n,1);
# randkl = rand(n,1);
randkl <- runif(nrow(am), 0, 1)

# am.kl2 = kl;
# am.kl3 = kl;
# am.kl4 = kl;

am$kl2 <- 0
am$kl3 <- 0
am$kl4 <- 0

# for j = 1:n
# if randkl(j)>(pin.p_KL2init + pin.p_KL3init)
# am.kl4(j) = am.oa(j);
# am.sf6d(j) = am.sf6d(j) - pin.c14_kl4;
# else if randkl(j) > pin.p_KL2init
# am.kl3(j) = am.oa(j);
# am.sf6d(j) = am.sf6d(j) - pin.c14_kl3;
# else
#   am.kl2(j) = am.oa(j);
# am.sf6d(j) = am.sf6d(j) - pin.c14_kl2;
# end
# end
# end

Prob_KL2 <- pin$Live[which(pin$Parameter == "p_KL2init")]
Prob_KL3 <- pin$Live[which(pin$Parameter == "p_KL3init")]

# very slow, vectorise the section below

# allocate to KL levels based on random number and OA status
am$kl4 <- ifelse(randkl > (Prob_KL2 + Prob_KL3), am$oa, 0)
am$kl3 <- ifelse((randkl > Prob_KL2) & (randkl <= (Prob_KL2 + Prob_KL3)), am$oa, 0)
am$kl2 <- ifelse(randkl <= Prob_KL2, am$oa, 0)

# set impcat of KL levels on SF6D
am$sf6d <- am$sf6d - (pin$Live[which(pin$Parameter == "c14_kl4")] * am$kl4)
am$sf6d <- am$sf6d - (pin$Live[which(pin$Parameter == "c14_kl3")] * am$kl3)
am$sf6d <- am$sf6d - (pin$Live[which(pin$Parameter == "c14_kl2")] * am$kl2)


# for(RowCounter in 1:nrow(am)){
#   if(randkl[RowCounter] > (Prob_KL2 + Prob_KL3)){
#     am$kl4[RowCounter] <- am$oa[RowCounter]
#     am$sf6d[RowCounter] <- am$sf6d[RowCounter] - pin$Live[which(pin$Parameter == "c14_kl4")]
#
#   } else if(randkl[RowCounter] > Prob_KL2){
#     am$kl3[RowCounter] <- am$oa[RowCounter]
#     am$sf6d[RowCounter] <- am$sf6d[RowCounter] - pin$Live[which(pin$Parameter == "c14_kl3")]
#
#   } else {
#     am$kl2[RowCounter] <- am$oa[RowCounter]
#     am$sf6d[RowCounter] <- am$sf6d[RowCounter] -pin$Live[which(pin$Parameter == "c14_kl2")]
#
#   }
# }

# am.kl_score = kl;
# am.kl_score = am.kl_score + 2.*am.kl2 + 3.*am.kl3 + 4.*am.kl4;
am$kl_score <- 0
am$kl_score <- am$kl_score + 2 * am$kl2 + 3 * am$kl3 + 4 * am$kl4
