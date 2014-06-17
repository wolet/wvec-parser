function [w,LOG] = train(tr_data,dev_data,it)

S = length(tr_data);
LOG.tr_err = [];
LOG.dev_err = [];

v0 = tr_data{1}.v;
w = zeros((length(v0)+1)^2,1);
for i = 1:it,
    LOG.narcs=0;
    LOG.nwrong = 0;
    for s = 1:S,
        arcs = tr_data{s};
        T = length(arcs);

        LOG.narcs = LOG.narcs + T;
        pred_arcs = [];
        for fr = 1:T,
            for to = 1:T,
%                prec_arcs = predict([arcs(to).v arcs(fr).v ]) %implement
%                your favorite ML algorithm to predict arc score
                pred_arcs = [pred_arcs;kron([arcs(to).v 1],[arcs(fr).v 1])]; % take outer product, it should correspond to poly kernel degree 2
            end
        end
        score = pred_arcs*w;
        score = reshape(score(:),T,T);
        score(logical(eye(T))) = -99999999999; %%%% how come -Inf make decoder choose root as head for all tokens? That's why I use this number instead -Inf
        score(1,:) = -9999999999;

        hguessed = decoder(score)'+1;
        hgold = [arcs(:).h];
        
        for tok = 2:T;
            if hguessed(tok) ~= hgold(tok)
                
               w = w + kron([arcs(hgold(tok)).v 1],[arcs(tok).v 1])';   % Add the correct arc
               w = w - kron([arcs(hguessed(tok)).v 1],[arcs(tok).v 1])';% Subtract the wrong
               
               % Train your favorite ML algorithm with correct and wrong
               % arcs
               % train([arcs(hguessed(tok)).v arcs(tok).v],0)
               % train([arcs(hgold(tok)).v arcs(tok).v],1)
               LOG.nwrong = LOG.nwrong + 1;
            end
        end
        if mod(s,10)==0,
        fprintf('error : %d\t %d:%d %5.3f\n',s,LOG.nwrong,LOG.narcs,LOG.nwrong/LOG.narcs);
        end
    end
    dev_err = testBasis(w,dev_data);
    tr_err = LOG.nwrong/LOG.narcs;
    fprintf('erro : %d\t tr :%5.3f\t dev:%5.3f\n',i,tr_err ,dev_err);
    LOG.tr_err = [LOG.tr_err, tr_err];
    LOG.dev_err = [LOG.dev_err,dev_err];
end
end
